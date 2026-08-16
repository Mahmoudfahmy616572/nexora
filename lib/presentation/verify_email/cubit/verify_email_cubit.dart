import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/errors/auth_failure.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'verify_email_state.dart';

/// Verifies the email confirmation OTP sent by Supabase.
class VerifyEmailCubit extends Cubit<VerifyEmailState> {
  VerifyEmailCubit({required this.repository}) : super(const VerifyEmailState());

  final AuthRepository repository;

  /// Submits the 6-digit code; on success the session is established.
  Future<void> verify({required String email, required String code}) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      await repository.verifyOtp(email: email.trim(), token: code.trim());
      emit(state.copyWith(loading: false, verified: true));
    } on AuthFailure catch (e) {
      emit(state.copyWith(loading: false, error: e.message));
    }
  }

  /// Re-sends the confirmation code after the countdown expires.
  Future<void> resend({required String email}) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      await repository.resendOtp(email: email.trim());
      emit(state.copyWith(loading: false));
    } on AuthFailure catch (e) {
      emit(state.copyWith(loading: false, error: e.message));
    }
  }
}
