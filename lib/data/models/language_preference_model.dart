import '../../domain/entities/app_language.dart';

/// Persisted representation of the language preference (storage format).
///
/// Kept in the data layer so the domain entity never leaks storage concerns.
class LanguagePreferenceModel {
  const LanguagePreferenceModel(this.code);

  factory LanguagePreferenceModel.fromEntity(AppLanguage language) =>
      LanguagePreferenceModel(language.code);

  final String code;

  AppLanguage toEntity() => AppLanguage.values.firstWhere(
        (l) => l.code == code,
        orElse: () => AppLanguage.english,
      );
}
