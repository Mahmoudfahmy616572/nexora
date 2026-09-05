import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';

/// Thin wrapper over the Supabase auth client.
///
/// The client is the app-wide singleton initialized in `main.dart`; it is only
/// touched when a method is actually called, so screens can render before the
/// connection is available.
class AuthRemoteDataSource {
  GoTrueClient get _auth {
    if (!SupabaseConfig.isConfigured) {
      throw const AuthException(
        'Supabase is not configured. Restart the app with '
        '--dart-define=SUPABASE_URL=... '
        '--dart-define=SUPABASE_PUBLISHABLE_KEY=...',
      );
    }
    return Supabase.instance.client.auth;
  }

  User? get currentUser => _auth.currentUser;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) =>
      _auth.signInWithPassword(email: email, password: password);

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) =>
      _auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

  Future<void> verifyOtp({required String email, required String token}) =>
      _auth.verifyOTP(email: email, token: token, type: OtpType.signup);

  Future<void> resendOtp({required String email}) =>
      _auth.resend(type: OtpType.signup, email: email);

  Future<void> resetPassword({required String email}) =>
      _auth.resetPasswordForEmail(email);

  Future<void> signOut() => _auth.signOut();

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Uri.base.origin,
      );
    } else {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw const AuthException('Google sign-in was cancelled');
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) throw const AuthException('Google sign-in failed: no ID token');
      await _auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
    }
  }
}
