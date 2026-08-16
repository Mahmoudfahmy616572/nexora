import '../entities/profile_data.dart';

/// Stores and loads the user's real career profile data.
///
/// Supabase is the source of truth when reachable; a SharedPreferences
/// fallback keeps it working signed out or offline.
abstract interface class ProfileRepository {
  /// Returns the stored profile, or `null` when nothing has been saved yet.
  Future<ProfileData?> load();

  Future<void> save(ProfileData profile);
}
