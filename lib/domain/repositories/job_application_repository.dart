import '../entities/job_application.dart';

/// Repository for the user's job applications (Tracker tab).
abstract class JobApplicationRepository {
  /// Returns the stored applications, or `null` when nothing has been saved
  /// anywhere yet (caller seeds demo data in that case).
  Future<List<JobApplication>?> load();

  Future<void> saveAll(List<JobApplication> apps);
}
