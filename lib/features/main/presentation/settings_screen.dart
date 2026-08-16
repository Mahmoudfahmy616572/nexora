import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/locale_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/app_language.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/data_sources/auth_remote_data_source.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../core/router/app_router.dart';

/// Profile / settings screen — reachable from the Home header avatar.
///
/// Shows the signed-in account, a language switch, and a "Sign out" action
/// that ends the Supabase session and returns to the sign-in screen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardHi,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l10n.settingsSignOutConfirm, style: AppTextStyles.cardTitle),
        content: Text(l10n.settingsSignOutBody, style: AppTextStyles.bodySub),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.settingsCancel, style: AppTextStyles.bodySub),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.settingsSignOut,
              style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await AuthRepositoryImpl(AuthRemoteDataSource()).signOut();
      if (!context.mounted) return;
      GoRouter.of(context).go(Routes.login);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.settingsSignOutError),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.cardHi,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCubit = context.watch<LocaleCubit>();
    final isArabic = localeCubit.state.language == AppLanguage.arabic;

    String name = 'Ahmed Al-Rashidi';
    String email = '';
    try {
      final user = AuthRepositoryImpl(AuthRemoteDataSource()).currentUser;
      if (user != null) {
        final fullName = user.fullName?.trim() ?? '';
        if (fullName.isNotEmpty) {
          name = fullName;
        } else if (user.email.isNotEmpty) {
          name = user.email.split('@').first;
        }
        email = user.email;
      }
    } catch (_) {
      // Supabase may be unavailable (e.g. widget tests) — keep the fallback.
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF020510), Color(0xFF060919), Color(0xFF0A051E)],
            stops: [0, 0.4, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(title: l10n.settingsTitle),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _AccountCard(name: name, email: email),
                    const SizedBox(height: 18),
                    _LanguageTile(
                      label: l10n.settingsLanguage,
                      isArabic: isArabic,
                      onToggle: localeCubit.toggleLanguage,
                    ),
                    const SizedBox(height: 24),
                    _SignOutButton(onPressed: () => _signOut(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              isRtl ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded,
              color: AppColors.text,
            ),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
          const SizedBox(width: 4),
          Text(title, style: AppTextStyles.screenTitle),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderMed),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.signatureGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            alignment: Alignment.center,
            child: Text(
              name.isEmpty ? 'N' : name[0].toUpperCase(),
              style: const TextStyle(
                fontFamily: AppTextStyles.displayFont,
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.cardTitle, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  email.isEmpty ? l10n.settingsAccount : email,
                  style: AppTextStyles.bodySub,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.isArabic,
    required this.onToggle,
  });

  final String label;
  final bool isArabic;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          TextButton(
            onPressed: onToggle,
            child: Text(
              isArabic ? 'English' : 'العربية',
              style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.red,
          side: const BorderSide(color: AppColors.red),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          l10n.settingsSignOut,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}
