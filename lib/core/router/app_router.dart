import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/main/presentation/main_shell.dart';
import '../../features/main/presentation/main_tab.dart';
import '../../features/main/presentation/settings_screen.dart';
import '../../presentation/career_dna/career_dna_review_screen.dart';
import '../../presentation/career_intake/adaptive_intake_screen.dart';
import '../../presentation/career_interview/interview_screen.dart';
import '../../presentation/onboarding/field_screen.dart';
import '../../presentation/onboarding/goal_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/onboarding/stage_screen.dart';
import '../../presentation/sign_in/sign_in_screen.dart';
import '../../presentation/verify_email/verify_email_screen.dart';
import '../../presentation/welcome/welcome_screen.dart';
import '../../presentation/target/target_list_screen.dart';
import '../../presentation/target/target_form_screen.dart';
import '../../features/main/presentation/studio/evaluation/cv_evaluation_screen.dart';
import '../../features/main/presentation/prep/interview_prep_screen.dart';
import '../../domain/entities/career_target.dart';

/// Route names for the entire application.
abstract final class Routes {
  static const String main = '/';
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
}

final GoRouter appRouter = GoRouter(
  initialLocation: Routes.welcome,
  redirect: (context, state) {
    // Restore the session: a returning signed-in user lands on the app shell
    // instead of the marketing welcome screen. Safe when Supabase is not
    // initialized (e.g., widget tests) — no redirect happens then.
    if (state.matchedLocation == Routes.welcome && _isSignedIn()) {
      return Routes.main;
    }
    return null;
  },
  routes: [
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
      builder: (context, state) => const AdaptiveIntakeScreen(),
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
    return Supabase.instance.client.auth.currentSession != null;
  } catch (_) {
    return false;
  }
}
