import 'package:equatable/equatable.dart';

/// State of the post-signup email verification screen.
class VerifyEmailState extends Equatable {
  const VerifyEmailState({
    this.loading = false,
    this.verified = false,
    this.error,
  });

  /// Whether a verify/resend call is in flight.
  final bool loading;

  /// Whether the OTP was accepted — the screen swaps to the success splash.
  final bool verified;

  /// User-facing error message.
  final String? error;

  VerifyEmailState copyWith({
    bool? loading,
    bool? verified,
    String? error,
    bool clearError = false,
  }) =>
      VerifyEmailState(
        loading: loading ?? this.loading,
        verified: verified ?? this.verified,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [loading, verified, error];
}
