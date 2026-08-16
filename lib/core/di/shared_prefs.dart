import 'package:shared_preferences/shared_preferences.dart';

/// Cached [SharedPreferences] instance, populated in [main]. Lets screens build
/// local data sources inside a synchronous `BlocProvider.create` without
/// re-reading the platform store.
SharedPreferences? kPrefs;
