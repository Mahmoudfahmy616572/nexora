import '../entities/career_target.dart';
import '../entities/cv_content.dart';
import '../entities/cv_evaluation.dart';
import '../entities/job_analysis.dart';
import '../entities/opportunity_analysis.dart';
import '../cv/cv_evaluator.dart';

/// Persistence + AI orchestration for CV evaluations.
abstract class CvEvaluationRepository {
  /// Runs the deterministic evaluation and (when available) the AI explanation/
  /// suggestion step. The numeric scores are ALWAYS the deterministic ones.
  /// Persists the evaluation (and its suggestions) and returns the result.
  Future<CvEvaluationResult> evaluate({
    required CvContent content,
    CareerTarget? target,
    JobAnalysis? analysis,
    OpportunityAnalysis? opportunity,
    required String userId,
    required String versionId,
    required String targetId,
  });

  /// The most recent evaluation for a specific version, or `null`.
  Future<CvEvaluation?> loadEvaluation(String versionId);

  Future<void> saveEvaluation(CvEvaluation evaluation);
}
