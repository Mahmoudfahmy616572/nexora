import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../data/data_sources/career_local_data_source.dart';
import '../../data/data_sources/career_remote_data_source.dart';
import '../../data/repositories/career_repository_impl.dart';
import '../../domain/entities/career_target.dart';
import 'cubit/target_cubit.dart';
import 'target_labels.dart';

class TargetFormScreen extends StatelessWidget {
  const TargetFormScreen({super.key, this.target});

  final CareerTarget? target;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final repo = CareerTargetRepositoryImpl(
          CareerRemoteDataSource(),
          CareerLocalDataSource(snap.data!),
        );
        return BlocProvider<TargetCubit>(
          create: (_) => TargetCubit(repo),
          child: _TargetFormView(target: target),
        );
      },
    );
  }
}

class _TargetFormView extends StatefulWidget {
  const _TargetFormView({this.target});

  final CareerTarget? target;

  @override
  State<_TargetFormView> createState() => _TargetFormViewState();
}

class _TargetFormViewState extends State<_TargetFormView> {
  final _formKey = GlobalKey<FormState>();
  late TargetType _type;
  final _role = TextEditingController();
  final _industry = TextEditingController();
  final _country = TextEditingController();
  final _seniority = TextEditingController();
  final _language = TextEditingController();
  final _company = TextEditingController();
  final _url = TextEditingController();
  final _description = TextEditingController();

  @override
  void initState() {
    super.initState();
    final t = widget.target;
    _type = t?.type ?? TargetType.job;
    _role.text = t?.role ?? '';
    _industry.text = t?.industry ?? '';
    _country.text = t?.countryRegion ?? '';
    _seniority.text = t?.seniority ?? '';
    _language.text = t?.language ?? '';
    _company.text = t?.company ?? '';
    _url.text = t?.url ?? '';
    _description.text = t?.jobDescription ?? '';
  }

  @override
  void dispose() {
    _role.dispose();
    _industry.dispose();
    _country.dispose();
    _seniority.dispose();
    _language.dispose();
    _company.dispose();
    _url.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final cubit = context.read<TargetCubit>();
    if (widget.target != null) {
      final updated = widget.target!.copyWith(
        type: _type,
        role: _role.text.trim(),
        industry: _industry.text.trim(),
        countryRegion: _country.text.trim(),
        seniority: _seniority.text.trim(),
        language: _language.text.trim(),
        company: _company.text.trim(),
        url: _url.text.trim(),
        jobDescription: _description.text.trim(),
        updatedAt: now,
      );
      await cubit.updateTarget(updated);
    } else {
      final created = CareerTarget(
        id: CareerTarget.newId(),
        userId: '',
        type: _type,
        role: _role.text.trim(),
        industry: _industry.text.trim(),
        countryRegion: _country.text.trim(),
        seniority: _seniority.text.trim(),
        language: _language.text.trim(),
        company: _company.text.trim(),
        url: _url.text.trim(),
        jobDescription: _description.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
      await cubit.createTarget(created);
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.target != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              title: isEditing ? l10n.targetEdit : l10n.targetAdd,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _SectionLabel(l10n.targetType),
                        _TypeSelector(value: _type, onChanged: (t) => setState(() => _type = t)),
                        const SizedBox(height: 16),
                        _TextField(
                          controller: _role,
                          label: l10n.targetRoleLabel,
                          hint: l10n.targetRoleHint,
                          required: true,
                        ),
                        const SizedBox(height: 12),
                        _TextField(controller: _industry, label: l10n.targetIndustryLabel, hint: l10n.targetIndustryHint),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _TextField(controller: _country, label: l10n.targetCountryLabel),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TextField(controller: _seniority, label: l10n.targetSeniorityLabel),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _TextField(controller: _company, label: l10n.targetCompanyLabel),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TextField(controller: _language, label: l10n.targetLanguageLabel),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _TextField(controller: _url, label: l10n.targetUrlLabel),
                        const SizedBox(height: 12),
                        _TextField(
                          controller: _description,
                          label: l10n.targetDescriptionLabel,
                          hint: '',
                          lines: 4,
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            foregroundColor: AppColors.background,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(l10n.targetSave, style: AppTextStyles.primaryButton),
                        ),
                        if (isEditing) ...[
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  backgroundColor: AppColors.card,
                                  title: Text(l10n.targetDelete, style: AppTextStyles.cardTitle),
                                  content: Text(l10n.targetDeleteConfirm, style: AppTextStyles.bodySub),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(false),
                                      child: Text(l10n.cancel, style: TextStyle(color: AppColors.textSub)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(true),
                                      child: Text(l10n.targetDelete, style: TextStyle(color: AppColors.amber)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true && context.mounted) {
                                await context.read<TargetCubit>().deleteTarget(widget.target!.id);
                                if (context.mounted) context.pop();
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.amber,
                              side: BorderSide(color: AppColors.amber.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(l10n.targetDelete),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.screenTitle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(), style: AppTextStyles.sectionLabel),
      );
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.value, required this.onChanged});

  final TargetType value;
  final ValueChanged<TargetType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final types = TargetType.values;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in types)
          ChoiceChip(
            label: Text(targetTypeLabel(l10n, type)),
            selected: value == type,
            onSelected: (_) => onChanged(type),
            selectedColor: AppColors.teal.withValues(alpha: 0.15),
            labelStyle: TextStyle(
              fontSize: 13,
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.w600,
              color: value == type ? AppColors.teal : AppColors.textSub,
            ),
            side: BorderSide(color: value == type ? AppColors.teal : AppColors.border),
            backgroundColor: AppColors.card,
          ),
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    this.hint = '',
    this.lines = 1,
    this.required = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int lines;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: lines,
      style: const TextStyle(color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint.isEmpty ? null : hint,
        filled: true,
        fillColor: AppColors.card,
        labelStyle: TextStyle(color: AppColors.textSub, fontFamily: AppTextStyles.fontFamily),
        hintStyle: TextStyle(color: AppColors.textMuted, fontFamily: AppTextStyles.fontFamily),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.teal),
        ),
      ),
      validator: required
          ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
          : null,
    );
  }
}
