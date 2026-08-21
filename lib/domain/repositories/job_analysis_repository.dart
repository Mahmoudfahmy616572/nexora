import '../entities/career_dna.dart';
import '../entities/career_target.dart';
import '../entities/job_analysis.dart';

/// Repository for the user's opportunity analyses (Analyze tab).
abstract class JobAnalysisRepository {
  /// Returns the stored analyses, or `null` when nothing has been saved
  /// anywhere yet (caller seeds demo data in that case).
  Future<List<JobAnalysis>?> load();

  Future<void> saveAll(List<JobAnalysis> analyses);

  /// Runs an analysis on [description] for the given [CareerDna] (and optional
  /// [CareerTarget]) using the hosted AI edge function when available, falling
  /// back to the offline deterministic [OpportunityMatchEngine].
  ///
  /// The deterministic engine is the single source of truth for the numeric
  /// score; the AI only supplies richer extraction + a recommendation.
  Future<JobAnalysis> analyze({
    required String description,
    required CareerDna dna,
    CareerTarget? target,
  });
}
