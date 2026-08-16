import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_language.dart';
import '../../domain/repositories/locale_repository.dart';
import 'locale_state.dart';

/// App-wide language switcher.
///
/// Holds the active language and persists every manual change through the
/// [LocaleRepository]. The initial language is resolved before the app boots
/// (saved preference first, then the device language), so the first frame is
/// already in the correct language.
class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit({
    required AppLanguage initialLanguage,
    required this.repository,
  }) : super(LocaleState(language: initialLanguage));

  final LocaleRepository repository;

  /// Switches the whole app to [language] and persists the choice.
  void setLanguage(AppLanguage language) {
    if (language == state.language) return;
    emit(LocaleState(language: language));
    repository.saveLanguage(language);
  }

  /// Toggles between English and Arabic.
  void toggleLanguage() => setLanguage(
        state.language == AppLanguage.english
            ? AppLanguage.arabic
            : AppLanguage.english,
      );
}
