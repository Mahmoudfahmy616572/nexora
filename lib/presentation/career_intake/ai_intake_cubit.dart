import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nexora/data/data_sources/career_local_data_source.dart';
import 'package:nexora/data/data_sources/career_remote_data_source.dart';
import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/profile_data.dart';
import 'package:nexora/domain/repositories/career_dna_repository.dart';
import 'package:nexora/data/repositories/career_dna_repository_impl.dart';

// ── Models ──────────────────────────────────────────────────────────────────

enum AiIntakeStatus { idle, loading, showing, importing, done, error }

enum ChoiceType { single, multi, other }

class AiIntakeChoice {
  const AiIntakeChoice({
    required this.label,
    required this.value,
    this.type = ChoiceType.single,
  });
  final String label;
  final String value;
  final ChoiceType type;
}

class AiIntakeTurn {
  const AiIntakeTurn({
    required this.question,
    required this.answer,
    this.choices = const [],
    this.feedback,
  });
  final String question;
  final String answer;
  final List<AiIntakeChoice> choices;
  final String? feedback;
}

// ── State ───────────────────────────────────────────────────────────────────

class AiIntakeState extends Equatable {
  const AiIntakeState({
    this.status = AiIntakeStatus.idle,
    this.turns = const [],
    this.currentQuestion = '',
    this.currentChoices = const [],
    this.currentFeedback,
    this.currentType = ChoiceType.single,
    this.selectedValues = const {},
    this.stepNumber = 0,
    this.totalSteps = 6,
    this.merged,
    this.error,
    this.usedFallback = false,
    this.githubUsername = '',
  });

  final AiIntakeStatus status;
  final List<AiIntakeTurn> turns;
  final String currentQuestion;
  final List<AiIntakeChoice> currentChoices;
  final String? currentFeedback;
  final ChoiceType currentType;
  final Set<String> selectedValues;
  final int stepNumber;
  final int totalSteps;
  final CareerDna? merged;
  final String? error;
  final bool usedFallback;
  final String githubUsername;

  bool get canContinue => selectedValues.isNotEmpty;
  bool get isMulti => currentType == ChoiceType.multi;
  bool get hasOther => currentChoices.any((c) => c.type == ChoiceType.other);

  AiIntakeState copyWith({
    AiIntakeStatus? status,
    List<AiIntakeTurn>? turns,
    String? currentQuestion,
    List<AiIntakeChoice>? currentChoices,
    String? currentFeedback,
    ChoiceType? currentType,
    Set<String>? selectedValues,
    int? stepNumber,
    int? totalSteps,
    CareerDna? merged,
    String? error,
    bool? usedFallback,
    String? githubUsername,
    bool clearFeedback = false,
  }) {
    return AiIntakeState(
      status: status ?? this.status,
      turns: turns ?? this.turns,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      currentChoices: currentChoices ?? this.currentChoices,
      currentFeedback: clearFeedback ? null : (currentFeedback ?? this.currentFeedback),
      currentType: currentType ?? this.currentType,
      selectedValues: selectedValues ?? this.selectedValues,
      stepNumber: stepNumber ?? this.stepNumber,
      totalSteps: totalSteps ?? this.totalSteps,
      merged: merged ?? this.merged,
      error: error,
      usedFallback: usedFallback ?? this.usedFallback,
      githubUsername: githubUsername ?? this.githubUsername,
    );
  }

  @override
  List<Object?> get props => [
        status,
        turns,
        currentQuestion,
        currentChoices,
        currentFeedback,
        currentType,
        selectedValues,
        stepNumber,
        totalSteps,
        merged,
        error,
        usedFallback,
        githubUsername,
      ];
}

// ── Cubit ───────────────────────────────────────────────────────────────────

class AiIntakeCubit extends Cubit<AiIntakeState> {
  AiIntakeCubit({
    CareerDnaRepository? repository,
    required CareerDna initialDna,
  })  : _repository = repository ??
            CareerDnaRepositoryImpl(
              remote: CareerRemoteDataSource(),
              local: CareerLocalDataSource(null),
            ),
        _baseDna = initialDna,
        super(const AiIntakeState());

  final CareerDnaRepository _repository;
  final CareerDna _baseDna;

  // ── Public API ──────────────────────────────────────────────────────────

  Future<void> start(String language) async {
    emit(state.copyWith(status: AiIntakeStatus.loading));
    try {
      final data = await _repository.aiIntake(
        history: [],
        targetRole: _baseDna.targetRole,
        language: language,
      );
      debugPrint('[AI_INTAKE] start response: $data');
      final question = (data['question'] as String? ?? '').trim();
      if (data['done'] == true || question.isEmpty) {
        _finishWithProfile(data);
      } else {
        _emitQuestion(data, step: 1);
      }
    } on Object catch (e) {
      debugPrint('[AI_INTAKE] start error: $e');
      _finishWithFallback();
    }
  }

  void toggleChoice(String value) {
    if (state.currentType == ChoiceType.multi) {
      final set = {...state.selectedValues};
      if (!set.remove(value)) set.add(value);
      emit(state.copyWith(selectedValues: set));
    } else {
      emit(state.copyWith(selectedValues: {value}));
    }
  }

  Future<void> confirmSelection(String language) async {
    if (!state.canContinue) return;

    final answerText = state.selectedValues.join(', ');
    _recordTurn(answerText);
    await _nextQuestion(language);
  }

  Future<void> answerOther(String text, String language) async {
    if (text.trim().isEmpty) return;
    _recordTurn(text.trim());
    await _nextQuestion(language);
  }

  Future<void> confirmSelectionWithOther(String otherText, String language) async {
    final combined = [
      ...state.selectedValues,
      if (otherText.trim().isNotEmpty) otherText.trim(),
    ].join(', ');
    if (combined.isEmpty) return;
    _recordTurn(combined);
    await _nextQuestion(language);
  }

  void skip(String language) {
    _recordTurn('(skipped)');
    _nextQuestion(language);
  }

  void back() {
    if (state.turns.length <= 1) return;
    final updatedTurns = List<AiIntakeTurn>.from(state.turns)
      ..removeLast();
    final last = updatedTurns.last;
    emit(state.copyWith(
      status: AiIntakeStatus.showing,
      currentQuestion: last.question,
      currentChoices: last.choices,
      currentFeedback: last.feedback,
      currentType: _typeFromChoices(last.choices),
      selectedValues: const {},
      turns: updatedTurns,
      stepNumber: state.stepNumber - 1,
    ));
  }

  Future<void> finalize(String language) async {
    emit(state.copyWith(status: AiIntakeStatus.loading));
    try {
      final history = _buildHistory();
      final data = await _repository.aiIntake(
        history: history,
        targetRole: _baseDna.targetRole,
        language: language,
        mode: 'finalize',
      );
      _finishWithProfile(data);
    } on Object {
      _finishWithFallback();
    }
  }

  Future<void> importGitHub(String username, String language) async {
    final clean = username
        .replaceFirst(RegExp(r'^https?://github\.com/'), '')
        .replaceAll(RegExp(r'/$'), '')
        .trim();
    emit(state.copyWith(
      status: AiIntakeStatus.importing,
      githubUsername: clean,
    ));
    try {
      final data = await _repository.aiIntake(
        history: [],
        targetRole: _baseDna.targetRole,
        language: language,
        mode: 'github_import',
        githubUsername: clean,
      );
      _finishWithProfile(data);
    } on Object catch (e) {
      emit(state.copyWith(
        status: AiIntakeStatus.error,
        error: e.toString(),
      ));
    }
  }

  void forceFinish() {
    emit(state.copyWith(status: AiIntakeStatus.done, merged: _baseDna));
  }

  // ── Internal ────────────────────────────────────────────────────────────

  void _recordTurn(String answer) {
    final updatedTurns = List<AiIntakeTurn>.from(state.turns);
    if (updatedTurns.isNotEmpty) {
      final last = updatedTurns.last;
      updatedTurns[updatedTurns.length - 1] = AiIntakeTurn(
        question: last.question,
        answer: answer,
        choices: last.choices,
        feedback: last.feedback,
      );
    }
    emit(state.copyWith(turns: updatedTurns));
  }

  Future<void> _nextQuestion(String language) async {
    emit(state.copyWith(status: AiIntakeStatus.loading, clearFeedback: true));

    try {
      final history = _buildHistory();
      final data = await _repository.aiIntake(
        history: history,
        targetRole: _baseDna.targetRole,
        language: language,
      );
      debugPrint('[AI_INTAKE] next response: $data');

      if (data['done'] == true) {
        _finishWithProfile(data);
      } else {
        final question = data['question'] as String? ?? '';
        if (question.trim().isEmpty) {
          _finishWithProfile({'done': true, 'profile': data['profile']});
        } else {
          _emitQuestion(data, step: state.stepNumber + 1);
        }
      }
    } on Object {
      _finishWithFallback();
    }
  }

  void _emitQuestion(Map<String, dynamic> data, {required int step}) {
    var question = (data['question'] as String? ?? '').trim();
    final feedback = data['feedback'] as String?;
    final rawChoices = data['choices'] as List? ?? [];

    // If question is empty, use a generic fallback
    if (question.isEmpty) {
      question = 'Tell me more about your experience.';
    }

    final choices = rawChoices.map((c) {
      final m = c as Map<String, dynamic>;
      final typeName = m['type'] as String? ?? 'single';
      final type = typeName == 'multi'
          ? ChoiceType.multi
          : typeName == 'other'
              ? ChoiceType.other
              : ChoiceType.single;
      return AiIntakeChoice(
        label: m['label'] as String? ?? '',
        value: m['value'] as String? ?? '',
        type: type,
      );
    }).toList();

    // Heuristic: force multi-select for questions that clearly require it,
    // even if the LLM forgot to set type: "multi".
    final q = question.toLowerCase();
    final looksMulti = q.contains('technologies') ||
        q.contains('skills') ||
        q.contains('types of') ||
        q.contains('type of') ||
        q.contains('worked on') ||
        q.contains('platforms') ||
        q.contains('frameworks') ||
        q.contains('tools') ||
        q.contains('languages') ||
        q.contains('industries') ||
        q.contains('areas') ||
        q.contains('aspects') ||
        q.contains('multiple') ||
        q.contains('all that apply') ||
        q.contains('select all');

    final type = (looksMulti || choices.any((c) => c.type == ChoiceType.multi))
        ? ChoiceType.multi
        : ChoiceType.single;

    // Fallback: if no choices, add basic ones so the user can always proceed
    if (choices.isEmpty) {
      choices.addAll(const [
        AiIntakeChoice(label: 'Yes', value: 'yes'),
        AiIntakeChoice(label: 'No', value: 'no'),
        AiIntakeChoice(label: 'Other', value: 'other', type: ChoiceType.other),
      ]);
    }

    final updatedTurns = List<AiIntakeTurn>.from(state.turns)
      ..add(AiIntakeTurn(
        question: question,
        answer: '',
        choices: choices,
        feedback: feedback,
      ));

    emit(state.copyWith(
      status: AiIntakeStatus.showing,
      currentQuestion: question,
      currentChoices: choices,
      currentFeedback: feedback,
      currentType: type,
      selectedValues: const {},
      turns: updatedTurns,
      stepNumber: step,
    ));
  }

  void _finishWithProfile(Map<String, dynamic> data) {
    final profile = data['profile'] as Map<String, dynamic>?;
    if (profile != null) {
      emit(state.copyWith(
        status: AiIntakeStatus.done,
        merged: _mergeProfile(profile),
      ));
    } else {
      _finishWithFallback();
    }
  }

  void _finishWithFallback() {
    final answers = state.turns
        .where((t) => t.answer.isNotEmpty && t.answer != '(skipped)')
        .toList();
    if (answers.isEmpty) {
      emit(state.copyWith(
        status: AiIntakeStatus.done,
        merged: _baseDna,
        usedFallback: true,
      ));
      return;
    }
    final answerTexts = answers.map((t) => t.answer).join('; ');
    final skills = <String>[];
    final experience = <ProfileExperience>[];
    for (final turn in answers) {
      final q = turn.question.toLowerCase();
      final a = turn.answer;
      if (q.contains('skill') || q.contains('technolog') || q.contains('framework')) {
        skills.addAll(a.split(RegExp(r',\s*')).map((s) => s.trim()).where((s) => s.isNotEmpty));
      } else if (q.contains('experience') || q.contains('work') || q.contains('job')) {
        experience.add(ProfileExperience(role: a, company: '', description: a));
      }
    }
    emit(state.copyWith(
      status: AiIntakeStatus.done,
      merged: _baseDna.copyWith(
        profile: _baseDna.profile.copyWith(
          summary: answerTexts,
          experience: experience.isNotEmpty ? experience : _baseDna.profile.experience,
        ),
        skills: skills.isNotEmpty ? skills : _baseDna.skills,
      ),
      usedFallback: true,
    ));
  }

  List<Map<String, String>> _buildHistory() => state.turns
      .where((t) => t.answer.isNotEmpty)
      .map((t) => {'q': t.question, 'a': t.answer})
      .toList();

  ChoiceType _typeFromChoices(List<AiIntakeChoice> choices) =>
      choices.any((c) => c.type == ChoiceType.multi)
          ? ChoiceType.multi
          : ChoiceType.single;

  CareerDna _mergeProfile(Map<String, dynamic> p) {
    final summary = p['summary'] as String? ?? '';
    final targetRole = p['targetRole'] as String? ?? _baseDna.targetRole;

    final experience = (p['experience'] as List? ?? []).map((e) {
      final m = e as Map<String, dynamic>;
      return ProfileExperience(
        role: m['role'] as String? ?? '',
        company: m['company'] as String? ?? '',
        durationMonths: (m['durationMonths'] as num?)?.toInt() ?? 0,
        description: m['description'] as String? ?? '',
        bullets: (m['bullets'] as List? ?? []).map((b) => b.toString()).toList(),
        technologies:
            (m['technologies'] as List? ?? []).map((t) => t.toString()).toList(),
      );
    }).toList();

    final projects = (p['projects'] as List? ?? []).map((pr) {
      final m = pr as Map<String, dynamic>;
      final links = (m['links'] as List? ?? []).map((l) {
        final lm = l as Map<String, dynamic>;
        return ProjectLink(
          label: lm['label'] as String? ?? '',
          url: lm['url'] as String? ?? '',
        );
      }).toList();
      return ProfileProject(
        name: m['name'] as String? ?? '',
        description: m['description'] as String? ?? '',
        tech: (m['tech'] as List? ?? []).map((t) => t.toString()).toList(),
        links: links,
      );
    }).toList();

    final skills =
        (p['skills'] as List? ?? []).map((s) => s.toString()).toList();

    final education = (p['education'] as List? ?? []).map((e) {
      final m = e as Map<String, dynamic>;
      return ProfileEducation(
        degree: m['degree'] as String? ?? '',
        field: m['field'] as String? ?? '',
      );
    }).toList();

    final certifications = (p['certifications'] as List? ?? []).map((c) {
      final m = c as Map<String, dynamic>;
      return ProfileCertification(
        name: m['name'] as String? ?? '',
        link: m['link'] as String? ?? '',
      );
    }).toList();

    final achievements =
        (p['achievements'] as List? ?? []).map((a) => a.toString()).toList();
    final languages =
        (p['languages'] as List? ?? []).map((l) => l.toString()).toList();

    return _baseDna.copyWith(
      targetRole:
          targetRole.isNotEmpty ? targetRole : _baseDna.targetRole,
      profile: ProfileData(
        summary: summary.isNotEmpty ? summary : _baseDna.profile.summary,
        experience:
            experience.isNotEmpty ? experience : _baseDna.profile.experience,
        projects: projects.isNotEmpty ? projects : _baseDna.profile.projects,
        education:
            education.isNotEmpty ? education : _baseDna.profile.education,
        certifications: certifications.isNotEmpty
            ? certifications
            : _baseDna.profile.certifications,
        achievements: achievements.isNotEmpty
            ? achievements
            : _baseDna.profile.achievements,
        languages:
            languages.isNotEmpty ? languages : _baseDna.profile.languages,
      ),
      skills: skills.isNotEmpty ? skills : _baseDna.skills,
    );
  }
}
