import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../data/data_sources/career_local_data_source.dart';
import '../../../data/data_sources/career_remote_data_source.dart';
import '../../../data/repositories/career_repository_impl.dart';
import '../../../domain/entities/cv_profile.dart';
import '../../../domain/repositories/cv_repository.dart';
import 'widgets/app_chip.dart';
import 'widgets/progress_bar.dart';
import 'widgets/section_label.dart';

/// CV Studio — mirrors the design's Studio screen.
///
/// CVs are data-driven and persist across restarts (Supabase when signed in,
/// SharedPreferences offline): new CVs are created from a form, and each CV's
/// Preview / Optimize / Edit actions are functional.
class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

Color _atsColor(int ats) =>
    ats >= 90 ? AppColors.teal : ats >= 80 ? AppColors.amber : AppColors.red;

String _purposeLabel(AppLocalizations l10n, String code) => switch (code) {
      'Job' => l10n.studioPurposeJob,
      'Academic' => l10n.studioPurposeAcademic,
      _ => l10n.studioPurposeInternship,
    };

class _StudioScreenState extends State<StudioScreen> {
  static const List<String> _purposeOptions = ['Job', 'Academic', 'Internship'];

  static const List<CvProfile> _seedCvs = [
    CvProfile(id: 'cv1', title: 'Flutter Engineer', ats: 89, purpose: 'Job', updated: 'Aug 8', match: 82),
    CvProfile(id: 'cv2', title: 'Software Engineer', ats: 91, purpose: 'Job', updated: 'Aug 7', match: 88, best: true),
    CvProfile(id: 'cv3', title: "Master's Application", ats: 76, purpose: 'Academic', updated: 'Aug 5', match: 74),
  ];

  late List<CvProfile> _cvs = [..._seedCvs];
  CvRepository? _repository;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final repository = CvRepositoryImpl(
      CareerRemoteDataSource(),
      CareerLocalDataSource(prefs),
    );
    _repository = repository;
    final cvs = await repository.load();
    if (!mounted) return;
    if (cvs == null) {
      await repository.saveAll(_cvs);
      return;
    }
    setState(() => _cvs = cvs);
  }

  Future<void> _persistCvs() async {
    await _repository?.saveAll(_cvs);
  }

  Future<void> _showNewCvSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<_NewCvResult>(
      context: context,
      backgroundColor: AppColors.cardHi,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _NewCvSheet(purposeOptions: _purposeOptions),
    );
    if (result == null || !mounted) return;

    final ats = 84 + (result.title.length % 7);
    setState(() {
      _cvs = [
        CvProfile(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          title: result.title,
          ats: ats,
          purpose: result.purpose,
          updated: 'Just now',
          match: (ats - 8).clamp(0, 100),
        ),
        ..._cvs,
      ];
    });
    await _persistCvs();
    if (!mounted) return;
    _snack(l10n.studioCreatedSnack(result.title));
  }

  Future<void> _preview(CvProfile cv) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardHi,
      showDragHandle: true,
      builder: (_) => _PreviewSheet(cv: cv),
    );
  }

  Future<void> _optimize(CvProfile cv) async {
    final l10n = AppLocalizations.of(context)!;
    final newAts = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.cardHi,
      showDragHandle: true,
      builder: (_) => _OptimizeSheet(currentAts: cv.ats),
    );
    if (newAts == null || !mounted) return;

    setState(() {
      _cvs = [
        for (final c in _cvs)
          c.id == cv.id ? c.copyWith(ats: newAts, match: (newAts - 8).clamp(0, 100)) : c,
      ];
    });
    await _persistCvs();
    if (!mounted) return;
    _snack(l10n.studioOptimizedSnack(newAts));
  }

  Future<void> _edit(CvProfile cv) async {
    final l10n = AppLocalizations.of(context)!;
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => _CvRenameDialog(
        initialTitle: cv.title,
        title: l10n.studioRenameCv,
        hint: l10n.studioCvTitleHint,
        cancelLabel: l10n.studioCancel,
        saveLabel: l10n.studioSave,
        onCancel: () => Navigator.of(context).pop(),
        onSave: (value) => Navigator.of(context).pop(value),
      ),
    );
    if (newTitle == null || newTitle.isEmpty || !mounted) return;

    setState(() {
      _cvs = [for (final c in _cvs) c.id == cv.id ? c.copyWith(title: newTitle) : c];
    });
    await _persistCvs();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.cardHi,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StudioHeader(onNewCv: _showNewCvSheet),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel('${l10n.studioMyCvs} (${_cvs.length})'),
                for (final cv in _cvs)
                  _CvCard(
                    cv: cv,
                    onPreview: () => _preview(cv),
                    onOptimize: () => _optimize(cv),
                    onEdit: () => _edit(cv),
                  ),
                const SizedBox(height: 6),
                _CvBattleHint(onTap: () => _snack(l10n.studioCvBattleSoon)),
                const SizedBox(height: 14),
                SectionLabel(l10n.studioTemplates),
                _TemplateStrip(onTap: (name) => _snack(l10n.studioTemplateSelected(name))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioHeader extends StatelessWidget {
  const _StudioHeader({required this.onNewCv});

  final VoidCallback onNewCv;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              l10n.studioTitle,
              style: AppTextStyles.screenTitle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          GestureDetector(
            onTap: onNewCv,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 15, color: AppColors.background),
                  SizedBox(width: 6),
                  Text(
                    l10n.studioNewCv,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w700,
                      color: AppColors.background,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CvCard extends StatelessWidget {
  const _CvCard({required this.cv, required this.onPreview, required this.onOptimize, required this.onEdit});

  final CvProfile cv;
  final VoidCallback onPreview;
  final VoidCallback onOptimize;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cv.best ? AppColors.tealBdr : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cv.best)
            Container(height: 2, decoration: const BoxDecoration(gradient: LinearGradient(colors: AppColors.signatureGradient))),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            cv.title,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.cardTitle,
                          ),
                        ),
                        if (cv.best) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.star_rounded, size: 14, color: AppColors.amber),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        AppChip(label: _purposeLabel(l10n, cv.purpose), color: AppColors.purple, size: 10),
                        const SizedBox(width: 6),
                        Text('Updated ${cv.updated}', style: AppTextStyles.mono.copyWith(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${cv.ats}',
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: AppTextStyles.monoFont,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: _atsColor(cv.ats),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(l10n.studioAtsScore, style: const TextStyle(fontSize: 10, fontFamily: AppTextStyles.monoFont, letterSpacing: 0.8, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(label: l10n.studioAtsCompat, value: cv.ats.toDouble(), color: _atsColor(cv.ats)),
          Row(
            children: [
              Expanded(child: _ActionButton(icon: Icons.visibility_outlined, label: l10n.studioPreview, color: AppColors.textSub, bg: AppColors.cardHi, border: AppColors.border, onTap: onPreview)),
              const SizedBox(width: 8),
              Expanded(child: _ActionButton(icon: Icons.bolt_rounded, label: l10n.studioOptimize, color: AppColors.teal, bg: AppColors.tealBg, border: AppColors.tealBdr, onTap: onOptimize)),
              const SizedBox(width: 8),
              Expanded(child: _ActionButton(icon: Icons.edit_outlined, label: l10n.studioEdit, color: AppColors.purple, bg: AppColors.purpleBg, border: AppColors.purpleBdr, onTap: onEdit)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.color, required this.bg, required this.border, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(fontSize: 13, fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _CvBattleHint extends StatelessWidget {
  const _CvBattleHint({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.purpleBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.purpleBdr),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.studioCvBattle,
                  style: const TextStyle(fontSize: 13, fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.w600, color: AppColors.purple),
                ),
                SizedBox(height: 2),
                Text(l10n.studioCvBattleHint, style: AppTextStyles.bodySmall),
              ],
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.purple),
          ],
        ),
      ),
    );
  }
}

class _TemplateStrip extends StatelessWidget {
  const _TemplateStrip({required this.onTap});

  final ValueChanged<String> onTap;

  static const _templates = [
    ('ATS Minimal', AppColors.teal),
    ('Modern Pro', AppColors.purple),
    ('Academic', AppColors.amber),
    ('Tech', AppColors.green),
    ('Executive', Color(0xFFE879F9)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _templates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final (name, color) = _templates[i];
          return GestureDetector(
            onTap: () => onTap(name),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 110,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 3, color: color),
                      const SizedBox(height: 5),
                      Container(
                        height: 4,
                        width: 60,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.38),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 5),
                      _line(0.9),
                      _line(0.6),
                      _line(0.75),
                      const SizedBox(height: 5),
                      Container(height: 1, color: color.withValues(alpha: 0.2)),
                      const SizedBox(height: 5),
                      _line(0.8),
                      _line(0.5),
                      _line(0.7),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(name, textAlign: TextAlign.center, style: AppTextStyles.bodySmall.copyWith(fontSize: 11, height: 1.3)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _line(double width) => Container(
        height: 2,
        width: 74 * width,
        margin: const EdgeInsets.only(bottom: 3),
        color: AppColors.border,
      );
}

class _NewCvResult {
  const _NewCvResult({required this.title, required this.purpose});

  final String title;
  final String purpose;
}

class _NewCvSheet extends StatefulWidget {
  const _NewCvSheet({required this.purposeOptions});

  final List<String> purposeOptions;

  @override
  State<_NewCvSheet> createState() => _NewCvSheetState();
}

class _NewCvSheetState extends State<_NewCvSheet> {
  final TextEditingController _controller = TextEditingController();
  String _purpose = 'Job';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(_NewCvResult(title: title, purpose: _purpose));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          Text(l10n.studioCreateNewCv, style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          Text(l10n.studioNameHint, style: AppTextStyles.bodySub),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.studioCvTitleHint,
              filled: true,
              fillColor: AppColors.card,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
            style: const TextStyle(color: AppColors.text),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 14),
          Text(l10n.studioPurpose, style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final p in widget.purposeOptions)
                ChoiceChip(
                  label: Text(_purposeLabel(l10n, p)),
                  selected: _purpose == p,
                  onSelected: (_) => setState(() => _purpose = p),
                  selectedColor: AppColors.purple.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w600,
                    color: _purpose == p ? AppColors.purple : AppColors.textSub,
                  ),
                  side: BorderSide(color: _purpose == p ? AppColors.purple : AppColors.border),
                  backgroundColor: AppColors.card,
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.studioCreateCvBtn, style: AppTextStyles.primaryButton),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewSheet extends StatelessWidget {
  const _PreviewSheet({required this.cv});

  final CvProfile cv;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cv.title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          Row(
            children: [
              AppChip(label: _purposeLabel(l10n, cv.purpose), color: AppColors.purple, size: 10),
              const SizedBox(width: 6),
              Text('ATS ${cv.ats}%', style: AppTextStyles.mono.copyWith(color: _atsColor(cv.ats))),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cv.title, style: AppTextStyles.cardTitleSmall),
                const SizedBox(height: 2),
                const Text('Cairo, Egypt · ahmed.alrashidi@email.com', style: AppTextStyles.bodyMuted),
                const SizedBox(height: 10),
                Text(l10n.studioSummary, style: AppTextStyles.sectionLabel),
                const SizedBox(height: 4),
                const Text(
                  'Senior engineer with a track record of shipping production Flutter applications and scalable backends.',
                  style: AppTextStyles.bodySub,
                ),
                const SizedBox(height: 10),
                Text(l10n.studioExperience, style: AppTextStyles.sectionLabel),
                const SizedBox(height: 4),
                const Text('Flutter Engineer · Careem (2022 — present)', style: AppTextStyles.body),
                const Text('Software Engineer · ShipLink (2019 — 2022)', style: AppTextStyles.bodySub),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.studioClose, style: AppTextStyles.primaryButton),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptimizeSheet extends StatefulWidget {
  const _OptimizeSheet({required this.currentAts});

  final int currentAts;

  @override
  State<_OptimizeSheet> createState() => _OptimizeSheetState();
}

class _OptimizeSheetState extends State<_OptimizeSheet> {
  bool _working = true;

  late final int _newAts = (widget.currentAts + 6).clamp(0, 100);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _working = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: _working ? _buildWorking() : _buildDone(),
    );
  }

  Widget _buildWorking() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSub),
            ),
            SizedBox(width: 10),
            Text(l10n.studioOptimizing, style: AppTextStyles.body),
          ],
        ),
        const SizedBox(height: 14),
        const NexoraShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ShimmerBlock(height: 60, radius: 14),
              SizedBox(height: 10),
              ShimmerBlock(height: 60, radius: 14),
              SizedBox(height: 10),
              ShimmerBlock(height: 40, radius: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDone() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.auto_awesome_rounded, size: 34, color: AppColors.teal),
        const SizedBox(height: 10),
        Text(
          l10n.studioOptimizationComplete,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          '${l10n.studioAtsRaised} ${widget.currentAts}% ${l10n.studioAtsTo} $_newAts%',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySub,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 44,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(_newAts),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.studioDone, style: AppTextStyles.primaryButton),
          ),
        ),
      ],
    );
  }
}

class _CvRenameDialog extends StatefulWidget {
  const _CvRenameDialog({
    required this.initialTitle,
    required this.title,
    required this.hint,
    required this.cancelLabel,
    required this.saveLabel,
    required this.onCancel,
    required this.onSave,
  });

  final String initialTitle;
  final String title;
  final String hint;
  final String cancelLabel;
  final String saveLabel;
  final VoidCallback onCancel;
  final ValueChanged<String> onSave;

  @override
  State<_CvRenameDialog> createState() => _CvRenameDialogState();
}

class _CvRenameDialogState extends State<_CvRenameDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialTitle);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardHi,
      title: Text(widget.title, style: AppTextStyles.cardTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: const TextStyle(color: AppColors.text),
        decoration: InputDecoration(
          hintText: widget.hint,
          filled: true,
          fillColor: AppColors.card,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppColors.border),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: Text(widget.cancelLabel, style: AppTextStyles.bodySub),
        ),
        TextButton(
          onPressed: () => widget.onSave(_controller.text.trim()),
          child: Text(
            widget.saveLabel,
            style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
