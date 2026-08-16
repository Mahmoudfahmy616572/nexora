import '../entities/profile_section.dart';

/// Repository for the user's added Career DNA sections.
abstract class ProfileSectionRepository {
  /// Returns the stored custom sections, or `null` when nothing has been saved
  /// anywhere yet.
  Future<List<ProfileSection>?> load();

  Future<void> saveAll(List<ProfileSection> sections);
}
