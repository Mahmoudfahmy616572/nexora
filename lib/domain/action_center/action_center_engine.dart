import '../entities/career_dna.dart';
import '../entities/career_intelligence.dart';
import '../entities/career_target.dart';
import '../entities/cv_document.dart';
import '../entities/cv_evaluation.dart';
import '../entities/job_analysis.dart';
import '../entities/job_application.dart';
import 'action_center.dart';

/// Deterministic "next best action" engine for the Action Center.
///
/// Pure Dart: no AI, no HTTP, no Supabase, no UI/l10n dependencies. Given the
/// same canonical input it always returns the same single primary action.
class ActionCenterEngine {
  ActionCenterEngine._();

  /// Derives exactly ONE primary action from the user's canonical state.
  static ActionCenterState derive(ActionCenterInput input) {
    // 1. Career DNA incomplete → complete it first.
    if (_dnaNeedsCompletion(input.dna, input.intelligence)) {
      return _decision(ActionType.completeDna, priority: 100);
    }

    // 2. No target → define one.
    if (input.targets.isEmpty) {
      return _decision(ActionType.defineTarget, priority: 90);
    }
    final target = _selectTarget(input.targets);

    // 3. No opportunity analysis for the selected target → analyze one.
    final targetAnalyses =
        input.analyses.where((a) => a.targetId == target.id).toList();
    if (targetAnalyses.isEmpty) {
      return _decision(
        ActionType.analyzeOpportunity,
        targetId: target.id,
        priority: 80,
        metadata: {'targetRole': target.role},
      );
    }
    final analysis = _selectAnalysis(targetAnalyses);

    // 4. No CV associated with the target → create one.
    final targetDocs =
        input.documents.where((d) => d.targetId == target.id).toList();
    if (targetDocs.isEmpty) {
      return _decision(
        ActionType.createCv,
        targetId: target.id,
        analysisId: analysis.id,
        priority: 70,
        metadata: {'targetRole': target.role},
      );
    }
    final doc = _selectDoc(targetDocs);

    // Always reason about the CURRENT/latest version, never an obsolete one.
    final versions = input.versionsByDoc[doc.id] ?? const [];
    final version = _latestVersion(versions);
    if (version == null) {
      return _decision(
        ActionType.evaluateCv,
        targetId: target.id,
        documentId: doc.id,
        analysisId: analysis.id,
        priority: 60,
      );
    }

    // 5. Latest version never evaluated → evaluate it.
    final evaluation = _evaluationForVersion(input.evaluations, version.id);
    if (evaluation == null) {
      return _decision(
        ActionType.evaluateCv,
        targetId: target.id,
        documentId: doc.id,
        versionId: version.id,
        analysisId: analysis.id,
        priority: 60,
        metadata: {
          'targetRole': target.role,
          'documentTitle': doc.title,
        },
      );
    }

    // 6. Evaluation has meaningful pending suggestions → improve it.
    final pending = input.suggestions
        .where((s) => s.evaluationId == evaluation.id && _isActionable(s))
        .toList();
    if (pending.isNotEmpty) {
      return _decision(
        ActionType.improveCv,
        targetId: target.id,
        documentId: doc.id,
        versionId: version.id,
        evaluationId: evaluation.id,
        priority: 50,
        metadata: {
          'targetRole': target.role,
          'pendingCount': pending.length,
          'documentTitle': doc.title,
          'score': evaluation.overall,
        },
      );
    }

    // 7. Everything is ready → track applications.
    // 7b. …unless an application has reached an interview stage, or the user
    //     already has a readiness plan they can practice against.
    final interviewApp = _firstInterviewStageApplication(input.applications);
    final practiceRole = interviewApp?.role ?? target.role;
    final practiceCompany = interviewApp?.company ?? target.company ?? '';
    final practiceAppId = interviewApp?.id;

    if (input.hasInterviewPrep) {
      return _decision(
        ActionType.practiceInterview,
        priority: 30,
        metadata: {
          'targetRole': practiceRole,
          'company': practiceCompany,
          'applicationId': practiceAppId,
        },
      );
    }

    if (interviewApp != null) {
      return _decision(
        ActionType.prepareInterview,
        priority: 20,
        metadata: {
          'targetRole': interviewApp.role,
          'company': interviewApp.company,
          'applicationId': interviewApp.id,
        },
      );
    }

    return _decision(
      ActionType.trackApplications,
      targetId: target.id,
      documentId: doc.id,
      versionId: version.id,
      evaluationId: evaluation.id,
      priority: 10,
      metadata: {
        'targetRole': target.role,
        'score': evaluation.overall,
        'documentTitle': doc.title,
      },
    );
  }

  // --- Interview-stage applications -----------------------------------------

  /// True when [status] indicates the candidate is actively interviewing
  /// (interview / assessment / offer stages) and should prepare.
  static bool _isInterviewStage(String status) {
    final s = status.toLowerCase();
    return s.contains('interview') ||
        s.contains('assessment') ||
        s.startsWith('offer');
  }

  static JobApplication? _firstInterviewStageApplication(
    List<JobApplication> applications,
  ) {
    for (final a in applications) {
      if (_isInterviewStage(a.status)) return a;
    }
    return null;
  }

  // --- DNA completeness ------------------------------------------------------

  /// True when the user should complete their Career DNA before anything else.
  ///
  /// Reuses [CareerIntelligence] (no duplicated logic). Students / fresh
  /// graduates are NOT penalized for lacking professional experience.
  static bool _dnaNeedsCompletion(
    CareerDna? dna,
    CareerIntelligence? intelligence,
  ) {
    if (dna == null) return true;
    if (intelligence == null) return true;
    return intelligence.missingInformation.any(
      (g) => g != ProfileGap.targetRole && g != ProfileGap.experience,
    );
  }

  // --- Selection helpers (deterministic) -------------------------------------

  /// Most recently updated target; ties broken by most recently created.
  static CareerTarget _selectTarget(List<CareerTarget> targets) {
    final sorted = [...targets];
    sorted.sort((a, b) {
      final byUpdated = b.updatedAt.compareTo(a.updatedAt);
      if (byUpdated != 0) return byUpdated;
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted.first;
  }

  /// Prefer the analysis carrying a full [OpportunityAnalysis] detail.
  static JobAnalysis _selectAnalysis(List<JobAnalysis> analyses) {
    for (final a in analyses) {
      if (a.detail != null) return a;
    }
    return analyses.first;
  }

  /// Most recently updated document.
  static CvDocument _selectDoc(List<CvDocument> docs) {
    final sorted = [...docs];
    sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.first;
  }

  /// Current/latest version: newest by [CvVersion.updatedAt], then by number.
  static CvVersion? _latestVersion(List<CvVersion> versions) {
    if (versions.isEmpty) return null;
    final sorted = [...versions];
    sorted.sort((a, b) {
      final byUpdated = b.updatedAt.compareTo(a.updatedAt);
      if (byUpdated != 0) return byUpdated;
      return b.version.compareTo(a.version);
    });
    return sorted.first;
  }

  static CvEvaluation? _evaluationForVersion(
    List<CvEvaluation> evaluations,
    String versionId,
  ) {
    for (final e in evaluations) {
      if (e.versionId == versionId) return e;
    }
    return null;
  }

  // --- Suggestion meaningfulness ---------------------------------------------

  static const Set<String> _meaningfulSections = {
    'summary',
    'experience',
    'projects',
    'skills',
    'education',
    'certifications',
    'achievements',
    'languages',
    'header',
  };

  /// A pending suggestion is "actionable" only when it is meaningful.
  ///
  /// Target-linked suggestions are always actionable. Otherwise only suggestions
  /// touching a substantive content section count — cosmetic/formatting tweaks
  /// never block the user from progressing to tracking applications.
  static bool _isActionable(CvSuggestion s) {
    if (s.status != CvSuggestionStatus.pending) return false;
    if (s.targetRequirement.trim().isNotEmpty) return true;
    return _meaningfulSections.contains(s.section.trim().toLowerCase());
  }

  // --- Decision builder ------------------------------------------------------

  static ActionCenterState _decision(
    ActionType actionType, {
    String? targetId,
    String? analysisId,
    String? documentId,
    String? versionId,
    String? evaluationId,
    required int priority,
    Map<String, dynamic>? metadata,
  }) =>
      ActionCenterState(
        actionType: actionType,
        targetId: targetId,
        analysisId: analysisId,
        documentId: documentId,
        versionId: versionId,
        evaluationId: evaluationId,
        priority: priority,
        metadata: metadata,
      );
}
