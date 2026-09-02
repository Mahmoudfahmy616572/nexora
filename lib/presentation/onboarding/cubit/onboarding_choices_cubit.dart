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

  static const _kGoals = 'onboarding_goals';
  static const _kStage = 'onboarding_stage';
  static const _kField = 'onboarding_field';
  static const _kPrefsSet = 'onboarding_prefs';
  static const kOnboardingCompleted = 'onboarding_completed';

  /// Whether the user has completed the intake/onboarding flow.
  static bool get isOnboardingCompleted =>
      kPrefs?.getBool(kOnboardingCompleted) ?? false;

  /// Mark onboarding as completed.
  static void markOnboardingCompleted() {
    kPrefs?.setBool(kOnboardingCompleted, true);
  }

  /// Clear onboarding completion (e.g. on logout).
  static void clearOnboardingCompleted() {
    kPrefs?.remove(kOnboardingCompleted);
  }

  void _load() {
    final prefs = kPrefs!;
    final goalNames = prefs.getStringList(_kGoals) ?? const <String>[];
    final goals = {
      for (final name in goalNames)
        for (final v in CareerGoal.values)
          if (v.name == name) v,
    };
    final stage = _enum<CareerStage>(CareerStage.values, prefs.getString(_kStage));
    final field = _enum<TargetField>(TargetField.values, prefs.getString(_kField));
    final prefStrings = prefs.getStringList(_kPrefsSet) ?? const <String>[];
    final preferences = {
      for (final p in prefStrings) p,
    };
    emit(OnboardingChoicesState(
      goals: goals,
      stage: stage,
      targetField: field,
      preferences: preferences,
    ));
  }

  void _persist(OnboardingChoicesState next) {
    final prefs = kPrefs!;
    prefs.setStringList(
      _kGoals,
      next.goals.map((g) => g.name).toList(),
    );
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

  void toggleGoal(CareerGoal goal) {
    final set = {...state.goals};
    if (!set.remove(goal)) set.add(goal);
    _emit(state.copyWith(goals: set));
  }

  void setStage(CareerStage stage) => _emit(state.copyWith(stage: stage));

  void setField(TargetField field) => _emit(state.copyWith(targetField: field));

  void togglePreference(String preference) {
    final set = {...state.preferences};
    if (!set.remove(preference)) set.add(preference);
    _emit(state.copyWith(preferences: set));
  }

  void clear() {
    final prefs = kPrefs!;
    prefs.remove(_kGoals);
    prefs.remove(_kStage);
    prefs.remove(_kField);
    prefs.remove(_kPrefsSet);
    emit(const OnboardingChoicesState());
  }

  void _emit(OnboardingChoicesState next) {
    _persist(next);
    emit(next);
  }

  bool get hasAny => state.goals.isNotEmpty || state.stage != null || state.targetField != null;
}

class OnboardingChoicesState {
  const OnboardingChoicesState({
    this.goals = const {},
    this.stage,
    this.targetField,
    this.preferences = const {},
  });

  final Set<CareerGoal> goals;
  final CareerStage? stage;
  final TargetField? targetField;
  final Set<String> preferences;

  /// The primary goal — the first selected goal, used for CareerDna storage.
  CareerGoal? get goal => goals.isEmpty ? null : goals.first;

  OnboardingChoicesState copyWith({
    Set<CareerGoal>? goals,
    CareerStage? stage,
    TargetField? targetField,
    Set<String>? preferences,
  }) =>
      OnboardingChoicesState(
        goals: goals ?? this.goals,
        stage: stage ?? this.stage,
        targetField: targetField ?? this.targetField,
        preferences: preferences ?? this.preferences,
      );

  bool get hasAny => goals.isNotEmpty || stage != null || targetField != null;
}

T? _enum<T>(List<T> values, Object? name) {
  if (name == null) return null;
  for (final v in values) {
    if (v.toString().split('.').last == name) return v;
  }
  return null;
}
