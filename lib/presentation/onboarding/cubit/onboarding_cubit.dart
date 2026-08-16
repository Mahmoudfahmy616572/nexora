import 'package:flutter_bloc/flutter_bloc.dart';

import 'onboarding_state.dart';

/// Cubit for the onboarding carousel — tracks the visible slide.
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(const OnboardingState(page: 0, totalSlides: 3));

  /// Called by the [PageView] whenever the visible slide changes.
  void onPageChanged(int page) {
    if (page == state.page) return;
    emit(state.copyWith(page: page));
  }
}
