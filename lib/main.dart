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

  // Connect to Supabase. The client key is injected via --dart-define; the
  // service role key never ships in the app.
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  } else {
    debugPrint(
      'Supabase not configured. Run with '
      '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...',
    );
  }

  // Resolve the language before the first frame so the app never flashes
  // the wrong locale: saved preference first, device language as fallback.
  final prefs = await SharedPreferences.getInstance();
  kPrefs = prefs;
  final repository = LocaleRepositoryImpl(LocaleLocalDataSource(prefs));
  final deviceLanguage =
      WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  final language =
      await repository.loadLanguage() ?? AppLanguage.fromDeviceLanguage(deviceLanguage);

  runApp(NexoraApp(localeCubit: LocaleCubit(initialLanguage: language, repository: repository)));
}
