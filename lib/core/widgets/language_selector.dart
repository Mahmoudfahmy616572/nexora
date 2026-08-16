import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_language.dart';
import '../localization/locale_cubit.dart';
import '../localization/locale_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../l10n/app_localizations.dart';

/// Glassy pill language selector (globe + label + chevron).
///
/// Tapping opens a sheet with the supported languages (English / Arabic).
/// Shows the name of the currently active language.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key, this.compact = false});

  /// [compact] reduces padding on small screens.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final horizontal = compact ? 12.0 : 16.0;
    final vertical = compact ? 9.0 : 11.0;
    return BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final label = state.language == AppLanguage.arabic
            ? l10n.langArabic
            : l10n.langEnglish;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showLanguageSheet(context),
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
              decoration: BoxDecoration(
                color: AppColors.surfaceGlass,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0x3894A0B8)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language_rounded, size: 17, color: Color(0xFFD1D5DB)),
                  const SizedBox(width: 9),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 14, color: Color(0xFFE5E7EB)),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF9CA3AF)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final cubit = context.read<LocaleCubit>();
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.borderMed),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10, top: 2),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _LanguageOption(
                  label: l10n.langEnglish,
                  hint: 'English',
                  icon: Icons.language_rounded,
                  selected: cubit.state.language == AppLanguage.english,
                  onTap: () {
                    cubit.setLanguage(AppLanguage.english);
                    Navigator.of(sheetContext).pop();
                  },
                ),
                const SizedBox(height: 8),
                _LanguageOption(
                  label: l10n.langArabic,
                  hint: 'العربية',
                  icon: Icons.language_rounded,
                  selected: cubit.state.language == AppLanguage.arabic,
                  onTap: () {
                    cubit.setLanguage(AppLanguage.arabic);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.hint,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String hint;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.tealBg : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.teal.withValues(alpha: 0.45) : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: selected ? AppColors.teal : AppColors.textSub),
              const SizedBox(width: 12),
              Text(
                hint,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              if (selected)
                const Icon(Icons.check_rounded, size: 16, color: AppColors.teal),
            ],
          ),
        ),
      ),
    );
  }
}
