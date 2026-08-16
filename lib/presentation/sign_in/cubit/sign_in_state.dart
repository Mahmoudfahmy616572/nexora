import 'package:equatable/equatable.dart';

/// Where a sign-in attempt ended up.
enum SignInOutcome { none, signedIn, verificationRequired }

/// State of the sign-in / create-account screen.
class SignInState extends Equatable {
  const SignInState({
    this.loading = false,
    this.error,
    this.outcome = SignInOutcome.none,
  });

  final bool loading;

  /// User-facing error message, shown under the form.
  final String? error;

  /// The result of the last submitted action.
  final SignInOutcome outcome;

  SignInState copyWith({
    bool? loading,
    String? error,
    SignInOutcome? outcome,
    bool clearError = false,
  }) =>
      SignInState(
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        outcome: outcome ?? this.outcome,
      );

  @override
  List<Object?> get props => [loading, error, outcome];
}
