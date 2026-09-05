import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/brand_lockup.dart';
import '../career_dna/cubit/career_dna_cubit.dart';
import '../onboarding/cubit/onboarding_choices_cubit.dart';

/// Splash screen — brief branded moment shown on launch.
///
/// Renders the Nexora mark with a gentle scale + fade entrance, then routes to:
/// * signed-in + onboarding completed → main shell (`/`)
/// * signed-in + onboarding not completed → adaptive intake (`/intake`)
/// * signed-out → welcome (`/welcome`)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _navTimer = Timer(const Duration(milliseconds: 2100), _go);
  }

  void _go() {
    if (!mounted) return;
    final router = GoRouter.of(context);
    if (_isSignedIn()) {
      context.read<CareerDnaCubit>().load();
      router.go(OnboardingChoicesCubit.isOnboardingCompleted ? Routes.main : Routes.intake);
    } else {
      router.go(Routes.welcome);
    }
  }

  bool _isSignedIn() {
    try {
      return Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientBackground(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(size: 96),
                  const SizedBox(height: 20),
                  Text(
                    'NEXORA',
                    style: AppTextStyles.displayXl(36).copyWith(letterSpacing: 6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
