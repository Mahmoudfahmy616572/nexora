import 'package:equatable/equatable.dart';

/// Verified, user-provided identity and contact information.
///
/// This is the single source of truth for contact details that appear on the
/// generated CV.  All fields are user-authored; the system never fabricates
/// values.  Missing fields are stored as empty strings / lists.
class UserIdentity extends Equatable {
  const UserIdentity({
    this.fullName = '',
    this.professionalTitle = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.linkedinUrl = '',
    this.githubUrl = '',
    this.portfolioUrl = '',
  });

  final String fullName;
  final String professionalTitle;
  final String email;
  final String phone;
  final String location;
  final String linkedinUrl;
  final String githubUrl;
  final String portfolioUrl;

  bool get isEmpty =>
      fullName.isEmpty &&
      email.isEmpty &&
      phone.isEmpty &&
      location.isEmpty &&
      linkedinUrl.isEmpty &&
      githubUrl.isEmpty &&
      portfolioUrl.isEmpty;

  Map<String, Object> toJson() => {
        'full_name': fullName,
        'professional_title': professionalTitle,
        'email': email,
        'phone': phone,
        'location': location,
        'linkedin_url': linkedinUrl,
        'github_url': githubUrl,
        'portfolio_url': portfolioUrl,
      };

  factory UserIdentity.fromJson(Map<String, dynamic> json) => UserIdentity(
        fullName: json['full_name'] as String? ?? '',
        professionalTitle: json['professional_title'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        location: json['location'] as String? ?? '',
        linkedinUrl: json['linkedin_url'] as String? ?? '',
        githubUrl: json['github_url'] as String? ?? '',
        portfolioUrl: json['portfolio_url'] as String? ?? '',
      );

  UserIdentity copyWith({
    String? fullName,
    String? professionalTitle,
    String? email,
    String? phone,
    String? location,
    String? linkedinUrl,
    String? githubUrl,
    String? portfolioUrl,
  }) =>
      UserIdentity(
        fullName: fullName ?? this.fullName,
        professionalTitle: professionalTitle ?? this.professionalTitle,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        location: location ?? this.location,
        linkedinUrl: linkedinUrl ?? this.linkedinUrl,
        githubUrl: githubUrl ?? this.githubUrl,
        portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      );

  @override
  List<Object?> get props => [
        fullName,
        professionalTitle,
        email,
        phone,
        location,
        linkedinUrl,
        githubUrl,
        portfolioUrl,
      ];
}
