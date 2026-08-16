import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';

/// Supabase-backed storage for the career feature tables.
///
/// Every operation is scoped to the signed-in user; Row Level Security on the
/// server enforces the same rule. The client is only touched when a method is
/// actually called, and any failure (unconfigured, signed out, offline) bubbles
/// up as an exception so repositories can fall back to local storage.
class CareerRemoteDataSource {
  SupabaseClient get _client {
    if (!SupabaseConfig.isConfigured) {
      throw StateError('Supabase is not configured.');
    }
    return Supabase.instance.client;
  }

  Future<List<Map<String, dynamic>>> fetchAll(String table) async {
    final userId = _client.auth.currentUser!.id;
    final rows = await _client.from(table).select().eq('user_id', userId);
    return [
      for (final row in rows as List) Map<String, dynamic>.from(row as Map),
    ];
  }

  /// Replaces the user's rows in [table] with [rows] (delete-all + insert).
  Future<void> replaceAll(String table, List<Map<String, dynamic>> rows) async {
    final client = _client;
    final userId = client.auth.currentUser!.id;
    await client.from(table).delete().eq('user_id', userId);
    if (rows.isEmpty) return;
    await client.from(table).insert([
      for (final row in rows) {...row, 'user_id': userId},
    ]);
  }

  /// The user's declared skills (stored on their profile row).
  Future<List<String>> fetchSkills() async {
    final client = _client;
    final userId = client.auth.currentUser!.id;
    final rows = await client.from('profiles').select('skills').eq('id', userId);
    if (rows.isEmpty) return const [];
    final skills = rows.first['skills'];
    return skills == null ? const [] : [for (final s in skills as List) s as String];
  }

  Future<void> saveSkills(List<String> skills) async {
    final client = _client;
    final userId = client.auth.currentUser!.id;
    await client.from('profiles').update({'skills': skills}).eq('id', userId);
  }

  /// The user's real career profile (single row in `profile_content`).
  Future<Map<String, dynamic>?> fetchProfile() async {
    final client = _client;
    final userId = client.auth.currentUser!.id;
    final rows = await client.from('profile_content').select().eq('user_id', userId);
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first as Map);
  }

  Future<void> saveProfile(Map<String, dynamic> content) async {
    final client = _client;
    final userId = client.auth.currentUser!.id;
    await client.from('profile_content').upsert({
      ...content,
      'user_id': userId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Runs the hosted AI analysis edge function with the user's JWT.
  Future<Map<String, dynamic>> runAiAnalysis(Map<String, dynamic> input) async {
    final client = _client;
    final response = await client.functions.invoke('analyze', body: input);
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw StateError('AI returned an unexpected response');
    }
    if (data['error'] != null) {
      throw StateError(data['error'] as String);
    }
    return data;
  }

  /// Runs the hosted AI profile-builder edge function with the user's JWT.
  ///
  /// [input] mirrors the local [generateProfile] parameters:
  /// `{ interests, customInterests, goals, sentence }`.
  /// Returns `{ skills, profile }` where `profile` is a `ProfileData` JSON and
  /// `skills` is a flat list of strings.
  Future<Map<String, dynamic>> runAiProfileBuild(Map<String, dynamic> input) async {
    final client = _client;
    final response = await client.functions.invoke('build_profile', body: input);
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw StateError('AI returned an unexpected response');
    }
    if (data['error'] != null) {
      throw StateError(data['error'] as String);
    }
    if (data['profile'] is! Map || data['skills'] is! List) {
      throw StateError('AI returned an incomplete profile');
    }
    return data;
  }

  /// Runs the hosted AI draft-profile edge function. [input] is
  /// `{ target, education, experience, skills }` and the function returns a flat
  /// profile object. This normalizes it into `{ profile, skills }` so callers
  /// and the local fallback share one shape.
  Future<Map<String, dynamic>> runAiProfileDraft(Map<String, dynamic> input) async {
    final client = _client;
    final response = await client.functions
        .invoke('profile_draft', body: input)
        .timeout(const Duration(seconds: 30));
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw StateError('AI returned an unexpected response');
    }
    if (data['error'] != null) {
      throw StateError(data['error'] as String);
    }
    final skills = data['skills'];
    return {
      'profile': {
        'summary': data['summary'] ?? '',
        'experience': data['experience'] ?? const [],
        'projects': data['projects'] ?? const [],
        'education': data['education'] ?? const [],
        'certifications': data['certifications'] ?? const [],
        'achievements': data['achievements'] ?? const [],
        'languages': data['languages'] ?? const [],
      },
      'skills': skills is List ? skills : const [],
    };
  }

  /// Runs the contextual, multi-turn interview edge function. [body] is
  /// `{ context, history, language, finish }`. Returns the raw JSON (either
  /// `{ done, question }` or `{ done: true, profile }`).
  Future<Map<String, dynamic>> runAiInterview(Map<String, dynamic> body) async {
    final client = _client;
    final response = await client.functions
        .invoke('career_interview', body: body)
        .timeout(const Duration(seconds: 30));
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw StateError('AI returned an unexpected response');
    }
    if (data['error'] != null) {
      throw StateError(data['error'] as String);
    }
    return data;
  }

  /// The current Career DNA row from `career_dna`, or `null` if none yet.
  Future<Map<String, dynamic>?> fetchCareerDna() async {
    final client = _client;
    final userId = client.auth.currentUser!.id;
    final rows = await client.from('career_dna').select().eq('user_id', userId);
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first as Map);
  }

  Future<void> upsertCareerDna(Map<String, dynamic> row) async {
    final client = _client;
    final userId = client.auth.currentUser!.id;
    await client.from('career_dna').upsert({
      ...row,
      'user_id': userId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Version snapshots from `career_dna_versions`, newest first.
  Future<List<Map<String, dynamic>>> fetchVersions() async {
    final client = _client;
    final userId = client.auth.currentUser!.id;
    final rows = await client
        .from('career_dna_versions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return [for (final row in rows as List) Map<String, dynamic>.from(row as Map)];
  }

  Future<void> insertVersion(Map<String, dynamic> row) async {
    final client = _client;
    final userId = client.auth.currentUser!.id;
    await client.from('career_dna_versions').insert({
      ...row,
      'user_id': userId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
