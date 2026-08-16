import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nexora_buttons.dart';
import '../../../domain/entities/career_dna.dart';
import '../../../domain/entities/intake_question.dart';
import '../../../l10n/app_localizations.dart';
import '../career_dna/cubit/career_dna_cubit.dart';
import '../onboarding/cubit/onboarding_choices_cubit.dart';
import 'intake_config.dart';
import 'intake_widgets.dart';

/// Adaptive intake — a structured, configuration-driven form reimagined as a
/// friendly, progress-driven experience. Questions with a fixed set of answers
/// render as tappable choice cards; free-form fields use modern chip/text inputs.
/// The visible set is derived from stage / goal / field via [questionsFor].
class AdaptiveIntakeScreen extends StatefulWidget {
  const AdaptiveIntakeScreen({super.key});

  @override
  State<AdaptiveIntakeScreen> createState() => _AdaptiveIntakeScreenState();
}

class _AdaptiveIntakeScreenState extends State<AdaptiveIntakeScreen> {
  final Map<String, dynamic> _answers = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    final dna = context.read<CareerDnaCubit>().state.dna;
    if (dna != null) _prefillFrom(dna);
  }

  void _prefillFrom(CareerDna dna) {
    _answers['targetRole'] = dna.targetRole;
    _answers['targetIndustry'] = dna.targetIndustry;
    _answers['summary'] = dna.profile.summary;
    _answers['skills'] = [...dna.skills];
    _answers['education'] = [
      for (final e in dna.profile.education) {'degree': e.degree, 'field': e.field},
    ];
    _answers['experience'] = [
      for (final e in dna.profile.experience)
        {'role': e.role, 'company': e.company, 'years': e.years.toString()},
    ];
    _answers['projects'] = [
      for (final p in dna.profile.projects)
        {'name': p.name, 'description': p.description, 'tech': p.tech.join(', ')},
    ];
    _answers['certifications'] = [...dna.profile.certifications];
    _answers['achievements'] = [...dna.profile.achievements];
    _answers['languages'] = [...dna.profile.languages];
    for (final entry in dna.extras.entries) {
      _answers[entry.key] = entry.value;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrl(String key, {String? initial}) {
    return _controllers.putIfAbsent(key, () {
      final c = TextEditingController(text: initial ?? (_answers[key] as String? ?? ''));
      c.addListener(() => _answers[key] = c.text);
      return c;
    });
  }

  List<IntakeQuestion> get _visible {
    final choices = context.watch<OnboardingChoicesCubit>().state;
    return questionsFor(
      stage: choices.stage,
      goal: choices.goal,
      field: choices.targetField,
      answers: _answers,
    );
  }

  bool _isAnswered(IntakeQuestion q) {
    final v = _answers[q.key];
    if (v == null) return false;
    if (v is String) return v.trim().isNotEmpty;
    if (v is List) return v.isNotEmpty;
    return false;
  }

  void _continue() {
    final choices = context.read<OnboardingChoicesCubit>().state;
    final dna = applyAnswersToDna(
      base: CareerDna(
        goal: choices.goal,
        stage: choices.stage,
        targetField: choices.targetField,
        preferences: choices.preferences.toList(),
      ),
      answers: _answers,
    );
    if (!dna.hasMeaningfulContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.intakeEmptyError)),
      );
      return;
    }
    context.read<CareerDnaCubit>().updateDraft(dna);
    context.go(Routes.interview);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final questions = _visible;
    final answered = questions.where(_isAnswered).length;
    final percent = questions.isEmpty ? 0.0 : answered / questions.length;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 720 ? 760.0 : 560.0;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => context.go(Routes.field),
                        ),
                      ),
                      Text(l10n.intakeTitle, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 6),
                      Text(l10n.intakeSubtitle, style: AppTextStyles.bodySub.copyWith(height: 1.5)),
                      const SizedBox(height: 16),
                      _ProgressBar(percent: percent, answered: answered, total: questions.length),
                      const SizedBox(height: 18),
                      for (var i = 0; i < questions.length; i++) ...[
                        _QuestionCard(
                          index: i + 1,
                          total: questions.length,
                          question: questions[i],
                          answers: _answers,
                          ctrl: _ctrl,
                          onChange: () => setState(() {}),
                        ),
                        const SizedBox(height: 14),
                      ],
                      NexoraPrimaryButton(label: l10n.intakeContinue, onPressed: _continue),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.percent, required this.answered, required this.total});

  final double percent;
  final int answered;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0, end: percent),
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    backgroundColor: AppColors.borderViolet,
                    color: AppColors.violet,
                    minHeight: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('$answered/$total', style: AppTextStyles.bodySub),
          ],
        ),
        const SizedBox(height: 6),
        Text(l10n.intakeProgress(answered, total), style: AppTextStyles.bodySub),
      ],
    );
  }
}

/// One-time fade + slide entrance used to make the form feel alive.
class _Reveal extends StatefulWidget {
  const _Reveal({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _opacity = CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _offset, child: widget.child),
      );
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.total,
    required this.question,
    required this.answers,
    required this.ctrl,
    required this.onChange,
  });

  final int index;
  final int total;
  final IntakeQuestion question;
  final Map<String, dynamic> answers;
  final TextEditingController Function(String key, {String? initial}) ctrl;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final questionText = question.question(l10n);
    final helpText = question.help?.call(l10n);
    final placeholder = question.placeholder?.call(l10n);
    final hasChoice = question.options != null;

    final input = switch (question.inputType) {
      IntakeInputType.shortText => hasChoice
          ? _SingleChoiceField(
              options: question.options!,
              optionLabels: question.optionLabels?.call(l10n),
              selected: answers[question.key] as String?,
              onSelected: (v) {
                answers[question.key] = v;
                onChange();
              },
            )
          : IntakeTextField(controller: ctrl(question.key), label: questionText, hint: placeholder ?? ''),
      IntakeInputType.longText => IntakeTextField(
          controller: ctrl(question.key),
          label: questionText,
          hint: placeholder ?? '',
          maxLines: 3,
        ),
      IntakeInputType.tags => hasChoice
          ? _SuggestionField(
              key: ValueKey(question.key),
              suggestions: question.options!,
              optionLabels: question.optionLabels?.call(l10n),
              initial: (answers[question.key] as List<String>?) ?? const [],
              hint: placeholder ?? '',
              onChanged: (v) {
                answers[question.key] = v;
                onChange();
              },
            )
          : _TagsField(
              key: ValueKey(question.key),
              initial: (answers[question.key] as List<String>?) ?? const [],
              hint: placeholder ?? '',
              onChanged: (v) {
                answers[question.key] = v;
                onChange();
              },
            ),
      IntakeInputType.stringList => hasChoice
          ? _SuggestionField(
              key: ValueKey(question.key),
              suggestions: question.options!,
              optionLabels: question.optionLabels?.call(l10n),
              initial: (answers[question.key] as List<String>?) ?? const [],
              hint: placeholder ?? l10n.intakeAddAchievement,
              onChanged: (v) {
                answers[question.key] = v;
                onChange();
              },
            )
          : StringAdder(
              hint: placeholder ?? l10n.intakeAddAchievement,
              items: (answers[question.key] as List<String>?) ?? const [],
              onAdd: (v) {
                final list = [...(answers[question.key] as List<String>? ?? const []), v];
                answers[question.key] = list;
                onChange();
              },
              onRemove: (v) {
                final list = [...(answers[question.key] as List<String>? ?? const [])]..remove(v);
                answers[question.key] = list;
                onChange();
              },
            ),
      IntakeInputType.structuredList => _StructListField(
          key: ValueKey(question.key),
          schema: question.listSchema ?? const [],
          items: (answers[question.key] as List<Map<String, String>>?) ?? const [],
          label: questionText,
          onChanged: (items) {
            answers[question.key] = items;
            onChange();
          },
        ),
    };

    return _Reveal(
      delay: Duration(milliseconds: 35 * index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderViolet.withValues(alpha: 0.32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.violet.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_categoryIcon(question.category), size: 18, color: AppColors.violet),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(questionText, style: AppTextStyles.cardTitle)),
                if (hasChoice)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.violet.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.intakeTapHint,
                      style: const TextStyle(fontSize: 10, color: AppColors.violet, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            if (helpText != null) ...[
              const SizedBox(height: 6),
              Text(helpText, style: AppTextStyles.bodySub.copyWith(height: 1.5)),
            ],
            const SizedBox(height: 14),
            input,
          ],
        ),
      ),
    );
  }
}

IconData _categoryIcon(IntakeCategory c) {
  return switch (c) {
    IntakeCategory.identity => Icons.badge_outlined,
    IntakeCategory.education => Icons.school_outlined,
    IntakeCategory.experience => Icons.work_outline,
    IntakeCategory.projects => Icons.folder_outlined,
    IntakeCategory.skills => Icons.lightbulb_outline,
    IntakeCategory.achievements => Icons.emoji_events_outlined,
    IntakeCategory.languages => Icons.translate_outlined,
    IntakeCategory.certifications => Icons.verified_outlined,
    IntakeCategory.careerChanger => Icons.sync_alt_outlined,
    IntakeCategory.context => Icons.info_outline,
  };
}

/// Tap-to-select choice cards for questions with a fixed set of answers.
class _SingleChoiceField extends StatelessWidget {
  const _SingleChoiceField({
    required this.options,
    this.optionLabels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final List<String>? optionLabels;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < options.length; i++)
          _ChoiceChip(
            label: optionLabels != null ? optionLabels![i] : options[i],
            selected: selected == options[i],
            onTap: () => onSelected(options[i]),
          ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.violet.withValues(alpha: 0.16) : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.violet : AppColors.borderViolet.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.check_circle_rounded, size: 16, color: AppColors.violet),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? AppColors.violet : AppColors.text,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick-pick suggestion chips (tap to toggle) plus a manual add row. Used for
/// skills, languages, certifications and achievements.
class _SuggestionField extends StatefulWidget {
  const _SuggestionField({
    super.key,
    required this.suggestions,
    this.optionLabels,
    required this.initial,
    required this.hint,
    required this.onChanged,
  });

  final List<String> suggestions;
  final List<String>? optionLabels;
  final List<String> initial;
  final String hint;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_SuggestionField> createState() => _SuggestionFieldState();
}

class _SuggestionFieldState extends State<_SuggestionField> {
  late List<String> _items;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = [...widget.initial];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(_items);

  void _toggle(String value) {
    setState(() {
      _items = _items.contains(value) ? _items.where((e) => e != value).toList() : [..._items, value];
    });
    _emit();
  }

  void _add() {
    final parts = _controller.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return;
    setState(() {
      _items = {..._items, ...parts}.toList();
      _controller.clear();
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < widget.suggestions.length; i++)
              _ChoiceChip(
                label: widget.optionLabels != null
                    ? widget.optionLabels![i]
                    : widget.suggestions[i],
                selected: _items.contains(widget.suggestions[i]),
                onTap: () => _toggle(widget.suggestions[i]),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: IntakeTextField(controller: _controller, label: widget.hint, hint: widget.hint),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _add,
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.violet.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.violet.withValues(alpha: 0.45)),
                ),
                child: Center(
                  child: Text(
                    l10n.addLabel,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.violet),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_items.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in _items)
                Chip(
                  backgroundColor: AppColors.violet.withValues(alpha: 0.12),
                  side: BorderSide(color: AppColors.violet.withValues(alpha: 0.3)),
                  label: Text(item, style: const TextStyle(color: AppColors.text, fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.textSub),
                  onDeleted: () {
                    setState(() => _items.remove(item));
                    _emit();
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TagsField extends StatefulWidget {
  const _TagsField({super.key, required this.initial, required this.hint, required this.onChanged});

  final List<String> initial;
  final String hint;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_TagsField> createState() => _TagsFieldState();
}

class _TagsFieldState extends State<_TagsField> {
  late List<String> _items;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = [...widget.initial];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    final parts = _controller.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return;
    setState(() {
      _items = {..._items, ...parts}.toList();
      _controller.clear();
    });
    widget.onChanged(_items);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: IntakeTextField(controller: _controller, label: widget.hint, hint: widget.hint),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _commit,
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.violet.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.violet.withValues(alpha: 0.45)),
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.addLabel,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.violet),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_items.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in _items)
                Chip(
                  backgroundColor: AppColors.violet.withValues(alpha: 0.12),
                  side: BorderSide(color: AppColors.violet.withValues(alpha: 0.3)),
                  label: Text(item, style: const TextStyle(color: AppColors.text, fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.textSub),
                  onDeleted: () {
                    setState(() => _items.remove(item));
                    widget.onChanged(_items);
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StructListField extends StatefulWidget {
  const _StructListField({
    super.key,
    required this.schema,
    required this.items,
    required this.label,
    required this.onChanged,
  });

  final List<ListField> schema;
  final List<Map<String, String>> items;
  final String label;
  final ValueChanged<List<Map<String, String>>> onChanged;

  @override
  State<_StructListField> createState() => _StructListFieldState();
}

class _StructListFieldState extends State<_StructListField> {
  late List<Map<String, String>> _items;

  @override
  void initState() {
    super.initState();
    _items = [for (final i in widget.items) {...i}];
  }

  void _emit() => widget.onChanged(_items);

  void _edit(int index, String field, String value) {
    _items[index] = {..._items[index], field: value};
    _emit();
  }

  void _add() {
    setState(() => _items.add({for (final f in widget.schema) f.name: ''}));
    _emit();
  }

  void _remove(int index) {
    setState(() => _items.removeAt(index));
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _items.length; i++) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderViolet.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final field in widget.schema) ...[
                  _StructField(
                    key: ValueKey('$i-${field.name}'),
                    initial: _items[i][field.name] ?? '',
                    label: field.label(l10n),
                    maxLines: field.inputType == IntakeInputType.longText ? 3 : 1,
                    onChanged: (v) => _edit(i, field.name, v),
                  ),
                  const SizedBox(height: 8),
                ],
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => _remove(i),
                    child: Text(l10n.dnaEdit, style: const TextStyle(color: AppColors.textSub)),
                  ),
                ),
              ],
            ),
          ),
        ],
        GestureDetector(
          onTap: _add,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.violet.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.violet.withValues(alpha: 0.35)),
            ),
            alignment: Alignment.center,
            child: Text(l10n.addLabel, style: const TextStyle(color: AppColors.violet, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

/// Owns its own [TextEditingController] so typing reliably updates [onChanged].
class _StructField extends StatefulWidget {
  const _StructField({
    super.key,
    required this.initial,
    required this.label,
    required this.onChanged,
    this.maxLines = 1,
  });

  final String initial;
  final String label;
  final ValueChanged<String> onChanged;
  final int maxLines;

  @override
  State<_StructField> createState() => _StructFieldState();
}

class _StructFieldState extends State<_StructField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
    _controller.addListener(() => widget.onChanged(_controller.text));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IntakeTextField(
        controller: _controller,
        label: widget.label,
        maxLines: widget.maxLines,
      );
}


