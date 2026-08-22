import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/analysis/interview_prep_engine.dart';
import '../../../../domain/entities/career_target.dart';
import '../../../../domain/entities/interview_prep.dart';
import '../../../../domain/entities/job_analysis.dart';
import '../../../../domain/entities/opportunity_analysis.dart';
import '../../../../domain/repositories/career_dna_repository.dart';
import '../../../../domain/repositories/career_target_repository.dart';
import '../../../../domain/repositories/job_analysis_repository.dart';

enum InterviewPrepStatus { initial, loading, success, fallback }

/// Presentation state for the interview prep screen.
///
/// [fallback] means AI was unavailable and a deterministic plan built from the
/// opportunity analysis / DNA skills was shown instead. Nothing is fabricated.
class InterviewPrepState {
  const InterviewPrepState({
    this.status = InterviewPrepStatus.initial,
    this.plan,
    this.analysisAvailable = false,
    this.role = '',
    this.company = '',
  });

  final InterviewPrepStatus status;
  final InterviewPrepPlan? plan;

  /// True when an opportunity analysis existed for this target, meaning the
  /// gaps are requirement-backed rather than inferred from skills alone.
  final bool analysisAvailable;
  final String role;
  final String company;
}

class InterviewPrepCubit extends Cubit<InterviewPrepState> {
  InterviewPrepCubit({
    required this.dnaRepository,
    required this.targetRepository,
    required this.analysisRepository,
  }) : super(const InterviewPrepState());

  final CareerDnaRepository dnaRepository;
  final CareerTargetRepository targetRepository;
  final JobAnalysisRepository analysisRepository;

  /// Loads canonical data, picks focus areas deterministically, then asks the
  /// backend for a coaching plan. Falls back to a deterministic-only plan when
  /// any part of the pipeline fails.
  Future<void> prepare({
    required String role,
    required String company,
    required String language,
  }) async {
    emit(InterviewPrepState(
      status: InterviewPrepStatus.loading,
      role: role,
      company: company,
    ));
    OpportunityAnalysis? analysis;
    var focusAreas = const <String>[];
    try {
      final dna = await _safe(dnaRepository.load, null);
      final targets = await _safe(
        targetRepository.loadAll,
        const <CareerTarget>[],
      );
      final analyses =
          await _safe(analysisRepository.load, null) ?? const <JobAnalysis>[];

      final target = _matchTarget(targets, role, company);
      if (target != null) {
        for (final a in analyses) {
          if (a.targetId == target.id && a.detail != null) {
            analysis = a.detail;
            break;
          }
        }
      }

      focusAreas = analysis != null
          ? InterviewPrepEngine.selectFocusAreas(analysis)
          : InterviewPrepEngine.focusFromSkills(dna?.skills ?? const []);

      final plan = await dnaRepository.generateInterviewPlan(
        context: dna?.toContext() ?? <String, dynamic>{},
        focusAreas: focusAreas,
        language: language,
        targetRole: role,
        company: company.isEmpty ? null : company,
      );
      emit(InterviewPrepState(
        status: InterviewPrepStatus.success,
        plan: plan,
        analysisAvailable: analysis != null,
        role: role,
        company: company,
      ));
    } on Object {
      // Deterministic plan only: the gaps and rationale stay explainable.
      final areas = <PrepFocusArea>[
        for (final label in focusAreas)
          PrepFocusArea(
            requirement: label,
            why: InterviewPrepEngine.rationaleFor(analysis, label),
          ),
      ];
      emit(InterviewPrepState(
        status: InterviewPrepStatus.fallback,
        plan: InterviewPrepPlan(focusAreas: areas, deterministicOnly: true),
        analysisAvailable: analysis != null,
        role: role,
        company: company,
      ));
    }
  }

  /// Best-effort matching of a tracked target to this role/company.
  CareerTarget? _matchTarget(
    List<CareerTarget> targets,
    String role,
    String company,
  ) {
    if (targets.isEmpty || role.trim().isEmpty) return null;
    final r = role.toLowerCase();
    final c = company.toLowerCase();

    CareerTarget? byBoth;
    CareerTarget? byRole;
    for (final t in targets) {
      final tr = t.role.toLowerCase();
      final tc = (t.company ?? '').toLowerCase();
      final roleMatch =
          r.isNotEmpty && (tr.contains(r) || r.contains(tr));
      final companyMatch = c.isNotEmpty && tc.isNotEmpty && tc.contains(c);
      if (roleMatch && companyMatch) return t;
      byBoth ??= roleMatch && (t.company ?? '').isNotEmpty ? t : null;
      byRole ??= roleMatch ? t : null;
    }
    if (byBoth != null) return byBoth;
    if (byRole != null) return byRole;
    if (c.isNotEmpty) {
      for (final t in targets) {
        if ((t.company ?? '').toLowerCase().contains(c)) return t;
      }
    }
    return null;
  }

  Future<T> _safe<T>(Future<T> Function() run, T orElse) async {
    try {
      return await run();
    } on Object {
      return orElse;
    }
  }
}
