/// Supabase connection settings.
///
/// The project URL and **publishable key** are safe to ship in the client:
/// they sit in front of Row Level Security and cannot read data on their own.
/// They are baked in as defaults so the app runs out of the box (including
/// from Android Studio), and can still be overridden per environment via
/// `--dart-define`:
/// ```
/// flutter run --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
///              --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>
/// ```
///
/// Only the **anon / publishable** key belongs here. The service role key
/// bypasses Row Level Security and must never be shipped in the client.
abstract final class SupabaseConfig {
  static const String _urlOverride = String.fromEnvironment('SUPABASE_URL');
  static const String _keyOverride =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static const String _defaultUrl = 'https://lwjtjeuwqypoqswknkcy.supabase.co';
  static const String _defaultPublishableKey =
      'sb_publishable_OTe0wPswiRfxqrCI6abslg_BToyd5Rk';

  static String get url => _urlOverride.isNotEmpty ? _urlOverride : _defaultUrl;

  static String get publishableKey =>
      _keyOverride.isNotEmpty ? _keyOverride : _defaultPublishableKey;

  /// Whether the app has Supabase credentials to connect with.
  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
