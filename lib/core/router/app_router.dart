import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/common/presentation/pending_screen.dart';

/// Route names for the entire application.
abstract final class Routes {
  static const String welcome = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
}

final GoRouter appRouter = GoRouter(
  initialLocation: Routes.welcome,
  routes: [
    GoRoute(path: Routes.welcome, builder: (context, state) => const WelcomeScreen()),
    GoRoute(
      path: Routes.onboarding,
      builder: (context, state) => const PendingScreen(title: 'Onboarding'),
    ),
    GoRoute(
      path: Routes.login,
      builder: (context, state) => const PendingScreen(title: 'Sign in'),
    ),
  ],
);
