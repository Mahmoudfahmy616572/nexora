import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/shared_prefs.dart';
import 'core/localization/locale_cubit.dart';
import 'core/localization/locale_state.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/data_sources/career_local_data_source.dart';
import 'data/data_sources/career_remote_data_source.dart';
import 'data/repositories/career_dna_repository_impl.dart';
import 'domain/entities/app_language.dart';
import 'l10n/app_localizations.dart';
import 'presentation/career_dna/cubit/career_dna_cubit.dart';
import 'presentation/onboarding/cubit/onboarding_choices_cubit.dart';

/// Nexora — AI Career Intelligence Platform.
///
/// Drives the active [AppLanguage] into [MaterialApp] so every screen, string
/// and the text direction (LTR / RTL) follow the user's selection.
class NexoraApp extends StatelessWidget {
  const NexoraApp({super.key, required this.localeCubit});

  final LocaleCubit localeCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: localeCubit,
      child: BlocProvider(
        create: (_) => OnboardingChoicesCubit(),
        child: BlocProvider(
          create: (_) => CareerDnaCubit(
            repository: CareerDnaRepositoryImpl(
              remote: CareerRemoteDataSource(),
              local: CareerLocalDataSource(kPrefs),
            ),
          ),
          child: BlocBuilder<LocaleCubit, LocaleState>(
        buildWhen: (previous, current) => previous.language != current.language,
        builder: (context, state) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            scrollBehavior: const NexoraScrollBehavior(),
            onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
            theme: AppTheme.dark,
            locale: state.language == AppLanguage.arabic
                ? const Locale('ar')
                : const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            localeResolutionCallback: (locale, supportedLocales) {
              if (locale != null && locale.languageCode == 'ar') {
                return const Locale('ar');
              }
              return const Locale('en');
            },
            routerConfig: appRouter,
          );
        },
      ),
      ),
    ),
  );
  }
}
