import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/errors/auth_failure.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'sign_in_state.dart';

/// Drives the sign-in / create-account form against Supabase Auth.
class SignInCubit extends Cubit<SignInState> {
  SignInCubit({required this.repository}) : super(const SignInState());

  final AuthRepository repository;

  /// Signs in an existing user (email + password).
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      await repository.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      emit(state.copyWith(loading: false, outcome: SignInOutcome.signedIn));
    } on AuthFailure catch (e) {
      emit(state.copyWith(loading: false, error: e.message));
    }
  }

  /// Creates an account; Supabase sends an OTP confirmation to [email].
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      await repository.signUp(
        fullName: fullName.trim(),
        email: email.trim(),
        password: password,
      );
      emit(state.copyWith(
        loading: false,
        outcome: SignInOutcome.verificationRequired,
      ));
    } on AuthFailure catch (e) {
      emit(state.copyWith(loading: false, error: e.message));
    }
  }
}
