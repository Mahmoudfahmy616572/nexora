import '../entities/user_identity.dart';

/// Persistence for [UserIdentity].  Remote-first (Supabase) with local
/// fallback — same pattern as [CareerDnaRepository].
abstract class UserIdentityRepository {
  Future<UserIdentity?> load();
  Future<void> save(UserIdentity identity);
}
