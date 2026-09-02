import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/di/shared_prefs.dart';
import 'core/localization/locale_cubit.dart';
import 'data/data_sources/locale_local_data_source.dart';
import 'data/repositories/locale_repository_impl.dart';
import 'domain/entities/app_language.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      );
      await Supabase.instance.client.auth.getSession();
      final hasSession = Supabase.instance.client.auth.currentSession != null;
      debugPrint('[AUTH] Session restored: $hasSession');
    } catch (e) {
      debugPrint('[AUTH] Supabase init error: $e');
    }
  } else {
    debugPrint(
      'Supabase not configured. Run with '
      '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...',
    );
  }

  final prefs = await SharedPreferences.getInstance();
  kPrefs = prefs;
  final repository = LocaleRepositoryImpl(LocaleLocalDataSource(prefs));
  final deviceLanguage =
      WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  final language =
      await repository.loadLanguage() ?? AppLanguage.fromDeviceLanguage(deviceLanguage);

  runApp(NexoraApp(localeCubit: LocaleCubit(initialLanguage: language, repository: repository)));
}
