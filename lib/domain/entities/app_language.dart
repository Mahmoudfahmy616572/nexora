/// Application languages supported by Nexora.
enum AppLanguage {
  english('en'),
  arabic('ar');

  const AppLanguage(this.code);

  /// BCP-47 language code used for locale resolution and persistence.
  final String code;

  /// Resolves the device language code to a supported [AppLanguage].
  ///
  /// Only Arabic maps to Arabic; every other device language falls back to
  /// English (the app's primary language).
  static AppLanguage fromDeviceLanguage(String languageCode) =>
      languageCode.toLowerCase().startsWith('ar')
          ? AppLanguage.arabic
          : AppLanguage.english;
}
