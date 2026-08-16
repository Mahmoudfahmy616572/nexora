import '../entities/job_analysis.dart';
import '../entities/profile_data.dart';

/// Repository for the user's opportunity analyses (Analyze tab).
abstract class JobAnalysisRepository {
  /// Returns the stored analyses, or `null` when nothing has been saved
  /// anywhere yet (caller seeds demo data in that case).
  Future<List<JobAnalysis>?> load();

  Future<void> saveAll(List<JobAnalysis> analyses);

  /// Runs a real analysis on [description] against the candidate's profile
  /// using the hosted AI edge function. Throws when the AI is unavailable.
  ///
  /// [profile] grounds the AI's recommendation in the user's actual
  /// experience, projects, education, and certifications.
  Future<JobAnalysis> analyze({
    required String description,
    required List<String> skills,
    int? yearsOfExperience,
    String? education,
    ProfileData? profile,
  });
}
