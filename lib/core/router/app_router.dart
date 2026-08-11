import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/main/presentation/main_shell.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';

/// Route names for the entire application.
abstract final class Routes {
  static const String main = '/';
  static const String welcome = '/welcome';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
}

final GoRouter appRouter = GoRouter(
  initialLocation: Routes.main,
  routes: [
    GoRoute(path: Routes.main, builder: (context, state) => const MainShell()),
    GoRoute(path: Routes.welcome, builder: (context, state) => const WelcomeScreen()),
    GoRoute(
      path: Routes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: Routes.login,
      builder: (context, state) => const SignInScreen(),
    ),
  ],
);
