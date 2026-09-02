import 'package:flutter/foundation.dart';

import '../../domain/entities/user_identity.dart';
import '../../domain/repositories/user_identity_repository.dart';
import '../data_sources/career_local_data_source.dart';
import '../data_sources/career_remote_data_source.dart';

/// Default [UserIdentityRepository] — Supabase first, SharedPreferences
/// fallback.
class UserIdentityRepositoryImpl implements UserIdentityRepository {
  UserIdentityRepositoryImpl({
    required this._remote,
    required this._local,
  });

  final CareerRemoteDataSource _remote;
  final CareerLocalDataSource _local;

  @override
  Future<UserIdentity?> load() async {
    try {
      final row = await _remote.fetchUserIdentity();
      if (row != null) {
        await _local.writeUserIdentity(row);
        return UserIdentity.fromJson(row);
      }
    } on Object catch (e) {
      debugPrint('UserIdentity load remote failed, using local: $e');
    }
    final localRow = await _local.readUserIdentity();
    if (localRow == null) return null;
    return UserIdentity.fromJson(localRow);
  }

  @override
  Future<void> save(UserIdentity identity) async {
    final json = identity.toJson();
    try {
      await _remote.saveUserIdentity(json);
    } on Object catch (e) {
      debugPrint('UserIdentity remote save failed, caching locally: $e');
    }
    await _local.writeUserIdentity(json);
  }
}
