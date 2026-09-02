import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/main/presentation/main_shell.dart';
import '../../features/main/presentation/main_tab.dart';
import '../../features/main/presentation/settings_screen.dart';
import '../../presentation/career_dna/career_dna_review_screen.dart';
import '../../presentation/career_intake/ai_intake_screen.dart';
import '../../presentation/career_interview/interview_screen.dart';
import '../../presentation/onboarding/field_screen.dart';
import '../../presentation/onboarding/goal_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/onboarding/stage_screen.dart';
import '../../presentation/onboarding/cubit/onboarding_choices_cubit.dart';
import '../../presentation/sign_in/sign_in_screen.dart';
import '../../presentation/splash/splash_screen.dart';
import '../../presentation/verify_email/verify_email_screen.dart';
import '../../presentation/welcome/welcome_screen.dart';
import '../../presentation/target/target_list_screen.dart';
import '../../presentation/target/target_form_screen.dart';
import '../../features/main/presentation/studio/evaluation/cv_evaluation_screen.dart';
import '../../features/main/presentation/prep/interview_prep_screen.dart';
import '../../features/main/presentation/prep/interview_practice_screen.dart';
import '../../domain/entities/career_target.dart';

/// Route names for the entire application.
abstract final class Routes {
  static const String main = '/';
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String verify = '/verify';
  static const String settings = '/settings';
  static const String goal = '/goal';
  static const String stage = '/stage';
  static const String field = '/field';
  static const String intake = '/intake';
  static const String interview = '/interview';
  static const String dna = '/dna';
  static const String interviewPrep = '/interview-prep';
  static const String interviewPractice = '/interview-practice';
}

final GoRouter appRouter = GoRouter(
  initialLocation: Routes.splash,
  refreshListenable: GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange.map((_) => null),
  ),
  redirect: (context, state) {
    // Guard: never navigate back to the splash once past it (e.g. system back).
    if (state.matchedLocation == Routes.splash) {
      return null;
    }
    // A signed-in user shouldn't see the welcome screen (e.g. after a stale
    // session resolves mid-flow); send them to the correct place.
    if (state.matchedLocation == Routes.welcome && _isSignedIn()) {
      return OnboardingChoicesCubit.isOnboardingCompleted
          ? Routes.main
          : Routes.intake;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: Routes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: Routes.main,
      builder: (context, state) => MainShell(
        initialTab: state.extra is MainTab ? state.extra as MainTab : MainTab.home,
      ),
    ),
    GoRoute(path: Routes.welcome, builder: (context, state) => const WelcomeScreen()),
    GoRoute(
      path: Routes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: Routes.goal,
      builder: (context, state) => const GoalScreen(),
    ),
    GoRoute(
      path: Routes.stage,
      builder: (context, state) => const StageScreen(),
    ),
    GoRoute(
      path: Routes.field,
      builder: (context, state) => const FieldScreen(),
    ),
    GoRoute(
      path: Routes.intake,
      builder: (context, state) => const AiIntakeScreen(),
    ),
    GoRoute(
      path: Routes.interview,
      builder: (context, state) => const InterviewScreen(),
    ),
    GoRoute(
      path: Routes.dna,
      builder: (context, state) => const CareerDnaReviewScreen(),
    ),
    GoRoute(
      path: Routes.interviewPrep,
      builder: (context, state) => InterviewPrepScreen(
        extra: state.extra is Map ? state.extra! as Map<String, dynamic> : null,
      ),
    ),
    GoRoute(
      path: Routes.interviewPractice,
      builder: (context, state) => InterviewPracticeScreen(
        extra: state.extra is Map ? state.extra! as Map<String, dynamic> : null,
      ),
    ),
    GoRoute(
      path: Routes.login,
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: Routes.verify,
      builder: (context, state) => VerifyEmailScreen(
        email: state.extra as String?,
      ),
    ),
    GoRoute(
      path: Routes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/targets',
      builder: (context, state) => const TargetListScreen(),
    ),
    GoRoute(
      path: '/targets/form',
      builder: (context, state) => TargetFormScreen(target: state.extra as CareerTarget?),
    ),
    GoRoute(
      path: '/cv/:id/evaluate',
      builder: (context, state) => CvEvaluationScreen(
        documentId: state.pathParameters['id'] ?? '',
      ),
    ),
  ],
);

bool _isSignedIn() {
  try {
    final session = Supabase.instance.client.auth.currentSession;
    final isSigned = session != null;
    debugPrint('[AUTH] _isSignedIn: $isSigned, session: ${session?.accessToken != null ? "exists" : "null"}');
    return isSigned;
  } catch (e) {
    debugPrint('[AUTH] _isSignedIn error: $e');
    return false;
  }
}

/// Converts a [Stream] into a [Listenable] for GoRouter's [refreshListenable].
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
