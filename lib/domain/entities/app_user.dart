import 'package:equatable/equatable.dart';

/// A signed-in user in the Nexora domain.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.emailVerified = false,
  });

  final String id;
  final String email;
  final String? fullName;
  final bool emailVerified;

  @override
  List<Object?> get props => [id, email, fullName, emailVerified];
}
