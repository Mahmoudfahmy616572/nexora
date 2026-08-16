import '../entities/cv_profile.dart';

/// Repository for the user's CV versions (Studio tab).
abstract class CvRepository {
  /// Returns the stored CVs, or `null` when nothing has been saved anywhere
  /// yet (caller seeds demo data in that case).
  Future<List<CvProfile>?> load();

  Future<void> saveAll(List<CvProfile> cvs);
}
