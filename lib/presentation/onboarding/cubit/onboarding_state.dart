import 'package:equatable/equatable.dart';

/// State of the pre-auth onboarding carousel.
class OnboardingState extends Equatable {
  const OnboardingState({required this.page, required this.totalSlides});

  final int page;
  final int totalSlides;

  /// Whether the last slide is visible (swaps "Next" for the final CTA).
  bool get isLast => page == totalSlides - 1;

  OnboardingState copyWith({int? page}) =>
      OnboardingState(page: page ?? this.page, totalSlides: totalSlides);

  @override
  List<Object?> get props => [page, totalSlides];
}
