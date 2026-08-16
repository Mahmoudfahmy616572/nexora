import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local-only fallback storage for career data, used when Supabase is not
/// available (signed out, offline, or unconfigured).
///
/// [prefs] may be `null` (e.g. in tests, or before the platform store is read);
/// in that case every read returns a safe default and every write is a no-op so
/// the UI still renders without throwing.
class CareerLocalDataSource {
  CareerLocalDataSource(this._prefs);

  final SharedPreferences? _prefs;

  bool get _available => _prefs != null;

  Future<List<String>?> readList(String key) async =>
      _available ? _prefs!.getStringList(key) : null;

  Future<void> writeList(String key, List<String> values) async =>
      _prefs?.setStringList(key, values);

  Future<String?> readString(String key) async =>
      _available ? _prefs!.getString(key) : null;

  Future<void> writeString(String key, String value) async =>
      _prefs?.setString(key, value);

  /// The full Career DNA JSON, or `null` when nothing has been saved locally.
  Future<Map<String, dynamic>?> readCareerDna() async {
    if (!_available) return null;
    final raw = _prefs!.getString(_careerDnaKey);
    if (raw == null) return null;
    return jsonDecodeStrict(raw);
  }

  Future<void> writeCareerDna(Map<String, dynamic> row) async =>
      _prefs?.setString(_careerDnaKey, jsonEncodeSafe(row));

  /// Ordered version history (newest first) as encoded JSON strings.
  Future<List<Map<String, dynamic>>> readVersions() async {
    if (!_available) return const [];
    final raw = _prefs!.getString(_versionsKey);
    if (raw == null) return const [];
    final list = jsonDecodeStrictList(raw);
    return [for (final m in list) m];
  }

  Future<void> writeVersions(List<Map<String, dynamic>> versions) async =>
      _prefs?.setString(_versionsKey, jsonEncodeSafe(versions));
}

const String _careerDnaKey = 'career_dna_v1';
const String _versionsKey = 'career_dna_versions_v1';

Map<String, dynamic>? jsonDecodeStrict(String raw) {
  try {
    final result = jsonDecode(raw);
    return result is Map ? Map<String, dynamic>.from(result) : null;
  } catch (_) {
    return null;
  }
}

List<Map<String, dynamic>> jsonDecodeStrictList(String raw) {
  try {
    final result = jsonDecode(raw);
    if (result is List) {
      return [
        for (final e in result)
          if (e is Map) Map<String, dynamic>.from(e),
      ];
    }
  } catch (_) {
    // ignore
  }
  return const [];
}

String jsonEncodeSafe(Object value) => jsonEncode(value);
