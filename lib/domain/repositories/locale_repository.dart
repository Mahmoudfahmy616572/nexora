import '../entities/app_language.dart';

/// Persistence contract for the user's language preference.
abstract interface class LocaleRepository {
  /// Returns the saved language, or `null` when the user has never chosen one.
  Future<AppLanguage?> loadLanguage();

  /// Persists the user's language choice.
  Future<void> saveLanguage(AppLanguage language);
}
