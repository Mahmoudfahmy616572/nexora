import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/shared_prefs.dart';
import '../../../domain/entities/career_dna.dart';

/// Holds the lightweight identity the user picks *before* signing up, so it can be
/// carried through authentication into the adaptive intake.
///
/// Provided once at the app root (see [NexoraApp]) so every screen in the
/// pre-auth flow and the post-auth intake can read and write the same choices.
/// Choices are also persisted to [kPrefs] so they survive an app restart before
/// the user authenticates.
class OnboardingChoicesCubit extends Cubit<OnboardingChoicesState> {
  OnboardingChoicesCubit() : super(const OnboardingChoicesState()) {
    _load();
  }

  static const _kGoal = 'onboarding_goal';
  static const _kStage = 'onboarding_stage';
  static const _kField = 'onboarding_field';
  static const _kPrefsSet = 'onboarding_prefs';

  void _load() {
    final prefs = kPrefs!;
    final goal = _enum<CareerGoal>(CareerGoal.values, prefs.getString(_kGoal));
    final stage = _enum<CareerStage>(CareerStage.values, prefs.getString(_kStage));
    final field = _enum<TargetField>(TargetField.values, prefs.getString(_kField));
    final prefStrings = prefs.getStringList(_kPrefsSet) ?? const <String>[];
    final preferences = {
      for (final p in prefStrings) p,
    };
    emit(OnboardingChoicesState(
      goal: goal,
      stage: stage,
      targetField: field,
      preferences: preferences,
    ));
  }

  void _persist(OnboardingChoicesState next) {
    final prefs = kPrefs!;
    if (next.goal != null) {
      prefs.setString(_kGoal, next.goal!.name);
    } else {
      prefs.remove(_kGoal);
    }
    if (next.stage != null) {
      prefs.setString(_kStage, next.stage!.name);
    } else {
      prefs.remove(_kStage);
    }
    if (next.targetField != null) {
      prefs.setString(_kField, next.targetField!.name);
    } else {
      prefs.remove(_kField);
    }
    prefs.setStringList(_kPrefsSet, next.preferences.toList());
  }

  void setGoal(CareerGoal goal) => _emit(state.copyWith(goal: goal));

  void setStage(CareerStage stage) => _emit(state.copyWith(stage: stage));

  void setField(TargetField field) => _emit(state.copyWith(targetField: field));

  void togglePreference(String preference) {
    final set = {...state.preferences};
    if (!set.remove(preference)) set.add(preference);
    _emit(state.copyWith(preferences: set));
  }

  void clear() {
    final prefs = kPrefs!;
    prefs.remove(_kGoal);
    prefs.remove(_kStage);
    prefs.remove(_kField);
    prefs.remove(_kPrefsSet);
    emit(const OnboardingChoicesState());
  }

  void _emit(OnboardingChoicesState next) {
    _persist(next);
    emit(next);
  }

  bool get hasAny => state.goal != null || state.stage != null || state.targetField != null;
}

class OnboardingChoicesState {
  const OnboardingChoicesState({
    this.goal,
    this.stage,
    this.targetField,
    this.preferences = const {},
  });

  final CareerGoal? goal;
  final CareerStage? stage;
  final TargetField? targetField;
  final Set<String> preferences;

  OnboardingChoicesState copyWith({
    CareerGoal? goal,
    CareerStage? stage,
    TargetField? targetField,
    Set<String>? preferences,
  }) =>
      OnboardingChoicesState(
        goal: goal ?? this.goal,
        stage: stage ?? this.stage,
        targetField: targetField ?? this.targetField,
        preferences: preferences ?? this.preferences,
      );

  bool get hasAny => goal != null || stage != null || targetField != null;
}

T? _enum<T>(List<T> values, Object? name) {
  if (name == null) return null;
  for (final v in values) {
    if (v.toString().split('.').last == name) return v;
  }
  return null;
}
