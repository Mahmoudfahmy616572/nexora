/// Repository for the user's declared skills (used for real AI matching).
abstract class ProfileSkillsRepository {
  /// Returns the stored skills, or `null` when nothing has been saved yet.
  Future<List<String>?> load();

  Future<void> save(List<String> skills);
}
