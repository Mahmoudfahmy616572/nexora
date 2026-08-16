import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/utils/breakpoints.dart';
import 'cubit/welcome_cubit.dart';
import 'widgets/actions_section.dart';
import 'widgets/background_painter.dart';
import 'widgets/feature_panel.dart';
import 'widgets/hero_section.dart';
import 'widgets/top_bar.dart';

/// Welcome / landing — pre-auth gate (Screen 1 of the approved design).
///
/// Fully responsive: two-column hero on desktop, stacked on tablet/mobile.
/// The whole page scrolls so content can never overflow. The language switch
/// lives in the [WelcomeTopBar] at the start of the top row.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (_) => WelcomeCubit(),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: WelcomeBackgroundPainter()),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: AppBreakpointValues.of<EdgeInsets>(
                      context,
                      mobile: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                      desktop: const EdgeInsets.fromLTRB(46, 34, 46, 30),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const WelcomeTopBar(),
                        const SizedBox(height: 24),
                        const WelcomeHero(),
                        const SizedBox(height: 24),
                        const WelcomeFeaturePanel(),
                        const SizedBox(height: 22),
                        WelcomeActions(
                          onGetStarted: () => context.go(Routes.goal),
                          onSignIn: () => context.go(Routes.login),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
