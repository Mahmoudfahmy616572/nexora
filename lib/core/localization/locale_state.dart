import 'package:equatable/equatable.dart';

import '../../domain/entities/app_language.dart';

/// State of the app-wide language selection.
class LocaleState extends Equatable {
  const LocaleState({required this.language});

  /// The language currently used to render the whole application.
  final AppLanguage language;

  @override
  List<Object?> get props => [language];
}
