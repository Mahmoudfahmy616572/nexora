import 'package:flutter/material.dart';
import 'package:nexora/core/theme/app_colors.dart';
import 'package:nexora/core/theme/app_typography.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Duration Picker
// ─────────────────────────────────────────────────────────────────────────────

/// Smart duration picker. Shows current value as a tappable pill that opens
/// a modal with months/years toggle and number grid.
class DurationPicker extends StatelessWidget {
  const DurationPicker({
    super.key,
    required this.months,
    required this.onChanged,
  });

  final int months;
  final ValueChanged<int> onChanged;

  String get _label {
    if (months <= 0) return 'Select duration';
    if (months < 12) return '$months month${months == 1 ? '' : 's'}';
    final y = months / 12.0;
    return y == y.roundToDouble()
        ? '${y.toInt()} year${y.toInt() == 1 ? '' : 's'}'
        : '${y.toStringAsFixed(1)} years';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: months > 0 ? AppColors.teal.withValues(alpha: 0.4) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 17,
              color: months > 0 ? AppColors.teal : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _label,
                style: AppTextStyles.body.copyWith(
                  color: months > 0 ? AppColors.text : AppColors.textMuted,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _openPicker(BuildContext context) {
    showModalBottomSheet<_DurationResult>(
      context: context,
      backgroundColor: AppColors.cardHi,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _DurationPickerSheet(initialMonths: months),
    ).then((result) {
      if (result != null) onChanged(result.months);
    });
  }
}

class _DurationResult {
  const _DurationResult(this.months);
  final int months;
}

class _DurationPickerSheet extends StatefulWidget {
  const _DurationPickerSheet({required this.initialMonths});
  final int initialMonths;

  @override
  State<_DurationPickerSheet> createState() => _DurationPickerSheetState();
}

class _DurationPickerSheetState extends State<_DurationPickerSheet> {
  late bool _isYears;
  late int _number;

  @override
  void initState() {
    super.initState();
    final m = widget.initialMonths;
    if (m > 0 && m % 12 == 0 && m ~/ 12 <= 30) {
      _isYears = true;
      _number = m ~/ 12;
    } else {
      _isYears = false;
      _number = m > 0 ? m : 1;
    }
  }

  int get _max => _isYears ? 30 : 60;
  int get _selectedMonths => _isYears ? _number * 12 : _number;

  String _label(int n) {
    if (_isYears) {
      final y = n;
      return '$y year${y == 1 ? '' : 's'}';
    }
    return '$n month${n == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Duration', style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          Text(
            'How long was this role?',
            style: AppTextStyles.bodySub,
          ),
          const SizedBox(height: 16),

          // ── Months / Years Toggle ──
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ToggleBtn(
                    label: 'Months',
                    selected: !_isYears,
                    onTap: () => setState(() {
                      _isYears = false;
                      _number = _number.clamp(1, 60);
                    }),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _ToggleBtn(
                    label: 'Years',
                    selected: _isYears,
                    onTap: () => setState(() {
                      _isYears = true;
                      // Convert current months to years for display
                      _number = (_number / 12).ceil().clamp(1, 30);
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Selected Value Display ──
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.tealBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
              ),
              child: Text(
                _label(_number),
                style: AppTextStyles.metric.copyWith(
                  color: AppColors.teal,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Number Grid ──
          SizedBox(
            height: 240,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.0,
              ),
              itemCount: _max,
              itemBuilder: (context, i) {
                final n = i + 1;
                final selected = n == _number;
                return GestureDetector(
                  onTap: () => setState(() => _number = n),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.teal.withValues(alpha: 0.15) : AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? AppColors.teal : AppColors.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$n',
                      style: AppTextStyles.body.copyWith(
                        color: selected ? AppColors.teal : AppColors.text,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── Confirm Button ──
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(
                _DurationResult(_selectedMonths),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Confirm', style: AppTextStyles.primaryButton),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? AppColors.teal.withValues(alpha: 0.4) : Colors.transparent,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: selected ? AppColors.teal : AppColors.textMuted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Achievements Selector
// ─────────────────────────────────────────────────────────────────────────────

/// Smart achievements selector with field-aware suggestions.
class AchievementsSelector extends StatefulWidget {
  const AchievementsSelector({
    super.key,
    required this.achievements,
    required this.onChanged,
    this.field,
  });

  final List<String> achievements;
  final ValueChanged<List<String>> onChanged;
  final String? field;

  @override
  State<AchievementsSelector> createState() => _AchievementsSelectorState();
}

class _AchievementsSelectorState extends State<AchievementsSelector> {
  final _controller = TextEditingController();
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = [...widget.achievements];
  }

  @override
  void didUpdateWidget(AchievementsSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.achievements != widget.achievements) {
      _selected = [...widget.achievements];
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_AchievementCategory> get _suggestions {
    final field = widget.field?.toLowerCase() ?? '';
    final categories = <_AchievementCategory>[];

    // Programming / Software
    if (field.contains('program') ||
        field.contains('software') ||
        field.contains('flutter') ||
        field.contains('developer') ||
        field.contains('engineer') ||
        field.contains('mobile') ||
        field.contains('web') ||
        field.contains('backend') ||
        field.contains('frontend') ||
        field.contains('fullstack') ||
        field.contains('devops') ||
        field.isEmpty) {
      categories.add(_AchievementCategory(
        label: 'Engineering',
        icon: Icons.code_rounded,
        items: [
          'Shipped features used by thousands of users',
          'Reduced app load time by 40%',
          'Built and maintained CI/CD pipelines',
          'Led migration to a new framework',
          'Mentored 3 junior developers',
          'Reduced crash rate by 60%',
          'Implemented real-time sync for 10K+ users',
          'Optimized database queries improving response time by 50%',
          'Built reusable component library used across 5 teams',
          'Achieved 99.9% uptime for critical services',
        ],
      ));
    }

    // Design
    if (field.contains('design') ||
        field.contains('ui') ||
        field.contains('ux') ||
        field.contains('figma') ||
        field.contains('creative') ||
        field.isEmpty) {
      categories.add(_AchievementCategory(
        label: 'Design',
        icon: Icons.palette_rounded,
        items: [
          'Redesigned core flow, improving conversion by 25%',
          'Created design system used by 4 product teams',
          'Conducted 20+ user research sessions',
          'Reduced design-to-dev handoff time by 35%',
          'Led A/B testing that increased engagement by 18%',
          'Designed accessible UI meeting WCAG 2.1 AA standards',
          'Built interactive prototyping workflow for the team',
        ],
      ));
    }

    // Business / Marketing / Management
    if (field.contains('business') ||
        field.contains('market') ||
        field.contains('manage') ||
        field.contains('product') ||
        field.contains('strateg') ||
        field.contains('sales') ||
        field.contains('finance') ||
        field.isEmpty) {
      categories.add(_AchievementCategory(
        label: 'Impact',
        icon: Icons.trending_up_rounded,
        items: [
          'Grew revenue by 30% within 6 months',
          'Managed budget of \$500K+',
          'Led team of 8 across 3 departments',
          'Closed 15 enterprise deals in Q4',
          'Reduced operational costs by 20%',
          'Launched product in 3 new markets',
          'Achieved 120% of annual sales target',
          'Streamlined process reducing time-to-market by 25%',
        ],
      ));
    }

    // Always add Leadership & Communication
    categories.add(_AchievementCategory(
      label: 'Leadership',
      icon: Icons.groups_rounded,
      items: [
        'Led cross-functional team of 5+ members',
        'Mentored new hires during onboarding',
        'Presented technical proposals to senior leadership',
        'Organized internal knowledge-sharing sessions',
        'Drove adoption of best practices across the team',
        'Resolved critical production issue under pressure',
      ],
    ));

    return categories;
  }

  void _add(String value) {
    final v = value.trim();
    if (v.isEmpty || _selected.contains(v)) return;
    setState(() => _selected.add(v));
    widget.onChanged(_selected);
  }

  void _remove(String value) {
    setState(() => _selected.remove(value));
    widget.onChanged(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Selected Achievements ──
        if (_selected.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final a in _selected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.tealBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          a,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.teal),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _remove(a),
                        child: Icon(Icons.close_rounded, size: 14, color: AppColors.teal),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // ── Suggestions ──
        for (final cat in _suggestions) ...[
          Row(
            children: [
              Icon(cat.icon, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                cat.label,
                style: AppTextStyles.sectionLabel.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in cat.items)
                if (!_selected.contains(item))
                  GestureDetector(
                    onTap: () => _add(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderMed),
                      ),
                      child: Text(
                        item,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSub),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // ── Custom Input ──
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: AppColors.text),
                decoration: InputDecoration(
                  hintText: 'Type your own achievement...',
                  hintStyle: AppTextStyles.bodySub,
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  isDense: true,
                ),
                onSubmitted: (v) {
                  _add(v);
                  _controller.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                _add(_controller.text);
                _controller.clear();
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded, size: 20, color: AppColors.background),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AchievementCategory {
  const _AchievementCategory({
    required this.label,
    required this.icon,
    required this.items,
  });
  final String label;
  final IconData icon;
  final List<String> items;
}

// ─────────────────────────────────────────────────────────────────────────────
// Experience Editor Sheet (custom, not generic SectionEditor)
// ─────────────────────────────────────────────────────────────────────────────

/// Full experience editor with duration picker and achievements.
class ExperienceEditorSheet extends StatefulWidget {
  const ExperienceEditorSheet({
    super.key,
    required this.entries,
    this.field,
  });

  final List<ExperienceEntry> entries;
  final String? field;

  @override
  State<ExperienceEditorSheet> createState() => _ExperienceEditorSheetState();
}

class ExperienceEntry {
  ExperienceEntry({
    this.role = '',
    this.company = '',
    this.durationMonths = 0,
    this.achievements = const [],
  });

  String role;
  String company;
  int durationMonths;
  List<String> achievements;

  bool get isEmpty => role.isEmpty && company.isEmpty;
}

class _ExperienceEditorSheetState extends State<ExperienceEditorSheet> {
  late final List<ExperienceEntry> _entries;
  int? _editingIndex;
  late final TextEditingController _roleCtrl;
  late final TextEditingController _companyCtrl;
  late int _durationMonths;
  late List<String> _achievements;

  @override
  void initState() {
    super.initState();
    _entries = [for (final e in widget.entries) _copyEntry(e)];
    _roleCtrl = TextEditingController();
    _companyCtrl = TextEditingController();
    _durationMonths = 0;
    _achievements = [];
  }

  ExperienceEntry _copyEntry(ExperienceEntry e) => ExperienceEntry(
        role: e.role,
        company: e.company,
        durationMonths: e.durationMonths,
        achievements: [...e.achievements],
      );

  @override
  void dispose() {
    _roleCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

  void _startEdit([int? index]) {
    setState(() {
      _editingIndex = index;
      if (index == null) {
        _roleCtrl.clear();
        _companyCtrl.clear();
        _durationMonths = 0;
        _achievements = [];
      } else {
        final e = _entries[index];
        _roleCtrl.text = e.role;
        _companyCtrl.text = e.company;
        _durationMonths = e.durationMonths;
        _achievements = [...e.achievements];
      }
    });
  }

  void _saveEntry() {
    final role = _roleCtrl.text.trim();
    final company = _companyCtrl.text.trim();
    if (role.isEmpty && company.isEmpty) return;

    setState(() {
      final entry = ExperienceEntry(
        role: role,
        company: company,
        durationMonths: _durationMonths,
        achievements: [..._achievements],
      );
      final idx = _editingIndex;
      if (idx == null) {
        _entries.add(entry);
      } else {
        _entries[idx] = entry;
      }
      _editingIndex = null;
      _roleCtrl.clear();
      _companyCtrl.clear();
      _durationMonths = 0;
      _achievements = [];
    });
  }

  void _remove(int index) {
    setState(() {
      _entries.removeAt(index);
      if (_editingIndex == index) _editingIndex = null;
    });
  }

  void _save() {
    Navigator.of(context).pop(
      _entries.where((e) => !e.isEmpty).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Experience', style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          Text(
            'Roles you have held — these back your match score.',
            style: AppTextStyles.bodySub,
          ),
          const SizedBox(height: 14),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Existing Entries ──
                  if (_entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text('No roles added yet.', style: AppTextStyles.bodySub),
                    )
                  else
                    for (var i = 0; i < _entries.length; i++)
                      _ExperienceCard(
                        entry: _entries[i],
                        onEdit: () => _startEdit(i),
                        onDelete: () => _remove(i),
                      ),

                  const SizedBox(height: 10),

                  // ── Add / Edit Form ──
                  Text(
                    _editingIndex == null ? 'Add role' : 'Edit role',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.purple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Role
                  TextField(
                    controller: _roleCtrl,
                    style: const TextStyle(color: AppColors.text),
                    decoration: InputDecoration(
                      labelText: 'Role',
                      hintText: 'e.g. Senior Flutter Engineer',
                      labelStyle: AppTextStyles.bodySub,
                      hintStyle: AppTextStyles.bodySub,
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Company
                  TextField(
                    controller: _companyCtrl,
                    style: const TextStyle(color: AppColors.text),
                    decoration: InputDecoration(
                      labelText: 'Company',
                      hintText: 'e.g. Careem',
                      labelStyle: AppTextStyles.bodySub,
                      hintStyle: AppTextStyles.bodySub,
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Duration
                  DurationPicker(
                    months: _durationMonths,
                    onChanged: (m) => setState(() => _durationMonths = m),
                  ),
                  const SizedBox(height: 14),

                  // Achievements
                  Text(
                    'Key Achievements',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AchievementsSelector(
                    achievements: _achievements,
                    onChanged: (a) => setState(() => _achievements = a),
                    field: widget.field,
                  ),
                  const SizedBox(height: 12),

                  // Add / Update Button
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _saveEntry,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _editingIndex == null ? 'Add' : 'Update',
                            style: AppTextStyles.primaryButton,
                          ),
                        ),
                      ),
                      if (_editingIndex != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => _startEdit(),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Save Button ──
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save changes', style: AppTextStyles.primaryButton),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card displaying a single experience entry.
class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final ExperienceEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String get _durationText {
    final m = entry.durationMonths;
    if (m <= 0) return '';
    if (m < 12) return '$m month${m == 1 ? '' : 's'}';
    final y = m / 12.0;
    return y == y.roundToDouble()
        ? '${y.toInt()}y'
        : '${y.toStringAsFixed(1)}y';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderMed),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.role.isEmpty ? 'Untitled role' : entry.role,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (entry.company.isNotEmpty) ...[
                            Flexible(
                              child: Text(
                                entry.company,
                                style: AppTextStyles.bodySub,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (_durationText.isNotEmpty)
                              Text(' · ', style: AppTextStyles.bodySub),
                          ],
                          if (_durationText.isNotEmpty)
                            Text(
                              _durationText,
                              style: AppTextStyles.bodySub.copyWith(color: AppColors.teal),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 17, color: AppColors.textMuted),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.textMuted),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (entry.achievements.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final a in entry.achievements.take(3))
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.purpleBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        a,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 10,
                          color: AppColors.purple,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (entry.achievements.length > 3)
                    Text(
                      '+${entry.achievements.length - 3} more',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Convert between ExperienceEntry and ProfileExperience.
class ExperienceEntryBridge {
  static List<ExperienceEntry> fromProfile(List<dynamic> experience) {
    return [
      for (final e in experience)
        ExperienceEntry(
          role: e.role,
          company: e.company,
          durationMonths: e.effectiveMonths,
          achievements: [...e.achievements],
        ),
    ];
  }

  static List<T> toProfile<T>(List<ExperienceEntry> entries, T Function(ExperienceEntry) converter) {
    return [for (final e in entries) converter(e)];
  }
}
