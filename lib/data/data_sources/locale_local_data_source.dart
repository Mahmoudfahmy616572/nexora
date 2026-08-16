import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_language.dart';
import '../models/language_preference_model.dart';

/// Local storage for the language preference backed by [SharedPreferences].
class LocaleLocalDataSource {
  LocaleLocalDataSource(this._prefs);

  static const String _languageKey = 'locale.language';

  final SharedPreferences _prefs;

  /// Reads the persisted language, or `null` when none was saved yet.
  AppLanguage? read() {
    final code = _prefs.getString(_languageKey);
    if (code == null) return null;
    return LanguagePreferenceModel(code).toEntity();
  }

  /// Persists the given language so it survives app restarts.
  Future<void> write(AppLanguage language) => _prefs.setString(
        _languageKey,
        LanguagePreferenceModel.fromEntity(language).code,
      );
}
