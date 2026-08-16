import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/errors/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_sources/auth_remote_data_source.dart';

/// [AuthRepository] backed by Supabase Auth.
///
/// Maps SDK errors to [AuthFailure] so the presentation layer never has to
/// depend on the Supabase package.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource);

  final AuthRemoteDataSource _dataSource;

  @override
  AppUser? get currentUser {
    final user = _dataSource.currentUser;
    return user == null ? null : _mapUser(user);
  }

  @override
  Stream<AppUser?> get authStateChanges =>
      _dataSource.authStateChanges.map((state) {
        final user = state.session?.user;
        return user == null ? null : _mapUser(user);
      });

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) =>
      _guard(() => _dataSource.signInWithPassword(email: email, password: password));

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) =>
      _guard(() => _dataSource.signUp(email: email, password: password, fullName: fullName));

  @override
  Future<void> verifyOtp({required String email, required String token}) =>
      _guard(() => _dataSource.verifyOtp(email: email, token: token));

  @override
  Future<void> resendOtp({required String email}) =>
      _guard(() => _dataSource.resendOtp(email: email));

  @override
  Future<void> resetPassword({required String email}) =>
      _guard(() => _dataSource.resetPassword(email: email));

  @override
  Future<void> signOut() => _guard(_dataSource.signOut);

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  AppUser _mapUser(User user) => AppUser(
        id: user.id,
        email: user.email ?? '',
        fullName: user.userMetadata?['full_name'] as String?,
        emailVerified: user.emailConfirmedAt != null,
      );
}
