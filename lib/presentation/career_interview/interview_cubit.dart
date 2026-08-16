import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/career_dna.dart';
import '../../domain/repositories/career_dna_repository.dart';

enum InterviewStatus { idle, generating, asking, done, error }

class InterviewTurn {
  const InterviewTurn({required this.question, required this.answer});

  final String question;
  final String answer;
}

class InterviewState {
  const InterviewState({
    this.status = InterviewStatus.idle,
    this.question,
    this.turns = const [],
    this.merged,
    this.error,
    this.usedFallback = false,
  });

  final InterviewStatus status;
  final String? question;
  final List<InterviewTurn> turns;
  final CareerDna? merged;
  final String? error;
  final bool usedFallback;

  InterviewState copyWith({
    InterviewStatus? status,
    String? question,
    List<InterviewTurn>? turns,
    CareerDna? merged,
    String? error,
    bool? usedFallback,
    bool clearError = false,
  }) =>
      InterviewState(
        status: status ?? this.status,
        question: question ?? this.question,
        turns: turns ?? this.turns,
        merged: merged ?? this.merged,
        error: clearError ? null : (error ?? this.error),
        usedFallback: usedFallback ?? this.usedFallback,
      );
}

/// Drives the contextual, multi-turn AI interview.
///
/// The screen calls [start] with the intake DNA; each [answer] (or [skip]) sends
/// the running transcript to the AI, which returns the next question or a final
/// structured profile. If the AI is unavailable, [merged] still holds the intake
/// DNA so the user can continue (graceful fallback, no data loss).
class InterviewCubit extends Cubit<InterviewState> {
  InterviewCubit({required this.repository}) : super(const InterviewState());

  final CareerDnaRepository repository;

  CareerDna? _base;
  String _language = 'en';

  Future<void> start(CareerDna dna, String language) async {
    _base = dna;
    _language = language;
    emit(const InterviewState().copyWith(status: InterviewStatus.generating));
    await _call(history: const [], finish: false);
  }

  Future<void> answer(String text) async {
    final q = state.question;
    if (q == null || _base == null) return;
    final turns = [...state.turns, InterviewTurn(question: q, answer: text.trim())];
    emit(state.copyWith(turns: turns, status: InterviewStatus.generating));
    await _call(history: _toHistory(turns), finish: false);
  }

  /// Skips the current question without an answer.
  Future<void> skip() async {
    if (state.question == null || _base == null) return;
    await answer('');
  }

  /// Removes the last exchange and returns to the previous question.
  void back() {
    if (state.turns.isEmpty || _base == null) return;
    final turns = [...state.turns]..removeLast();
    final prev = turns.isNotEmpty ? turns.last.question : null;
    emit(state.copyWith(turns: turns, status: InterviewStatus.asking, question: prev));
  }

  /// Asks the AI to finalize the profile now.
  Future<void> finish() async {
    if (_base == null) return;
    emit(state.copyWith(status: InterviewStatus.generating, clearError: true));
    await _call(history: _toHistory(state.turns), finish: true);
  }

  List<Map<String, dynamic>> _toHistory(List<InterviewTurn> turns) =>
      [for (final t in turns) {'q': t.question, 'a': t.answer}];

  Future<void> _call({
    required List<Map<String, dynamic>> history,
    required bool finish,
  }) async {
    try {
      final result = await repository.interview(
        context: _base!.toContext(),
        history: history,
        language: _language,
        finish: finish,
      );
      if (result.done) {
        final profile = result.profile ?? _base!.profile;
        final merged = _base!.copyWith(
          profile: profile,
          skills: _base!.skills,
        );
        emit(state.copyWith(status: InterviewStatus.done, merged: merged, question: null));
      } else {
        emit(state.copyWith(status: InterviewStatus.asking, question: result.question));
      }
    } on Object {
      // AI unavailable: keep the structured intake so nothing is lost.
      emit(state.copyWith(
        status: InterviewStatus.done,
        merged: _base,
        usedFallback: true,
        error: 'ai_unavailable',
      ));
    }
  }
}
