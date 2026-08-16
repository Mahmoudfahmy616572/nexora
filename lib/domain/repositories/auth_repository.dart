import '../entities/app_user.dart';

/// Contract for the app's authentication layer (Supabase Auth).
abstract interface class AuthRepository {
  /// Currently signed-in user, or `null` when signed out.
  AppUser? get currentUser;

  /// Emits whenever the auth session changes (sign in/out, token refresh).
  Stream<AppUser?> get authStateChanges;

  /// Signs in with email + password.
  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  /// Creates an account; Supabase sends an OTP to confirm the email.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  });

  /// Confirms the email with the 6-digit code from Supabase.
  Future<void> verifyOtp({required String email, required String token});

  /// Re-sends the confirmation OTP to [email].
  Future<void> resendOtp({required String email});

  /// Sends a password-reset email to [email] (no-op feedback to avoid leaking
  /// which addresses exist).
  Future<void> resetPassword({required String email});

  /// Ends the current session and returns to the signed-out state.
  Future<void> signOut();
}
