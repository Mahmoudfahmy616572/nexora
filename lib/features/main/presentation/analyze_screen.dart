import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'widgets/app_chip.dart';
import 'widgets/info_note.dart';
import 'widgets/progress_bar.dart';
import 'widgets/section_label.dart';

/// Opportunity Analyzer — mirrors the design's Analyze screen.
class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  bool _showResults = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Opportunity', style: AppTextStyles.screenTitle),
                const SizedBox(height: 14),
                _SegmentSwitch(value: _showResults, onChanged: (v) => setState(() => _showResults = v)),
                const SizedBox(height: 16),
              ],
            ),
          ),
          if (_showResults) const _AnalysisResults() else const _NewAnalysis(),
        ],
      ),
    );
  }
}

class _SegmentSwitch extends StatelessWidget {
  const _SegmentSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildSegment('My Analyses', true, () => onChanged(true)),
          _buildSegment('New Analysis', false, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _buildSegment(String label, bool isResults, VoidCallback onTap) {
    final selected = value == isResults;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.background : AppColors.textSub,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalysisResults extends StatelessWidget {
  const _AnalysisResults();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderMed),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 2, decoration: const BoxDecoration(gradient: LinearGradient(colors: AppColors.signatureGradient))),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Flutter Engineer', style: AppTextStyles.cardTitle),
                        SizedBox(height: 3),
                        Text('Careem · Dubai 🇦🇪', style: AppTextStyles.bodySub),
                      ],
                    ),
                    const AppChip(label: '2h ago'),
                  ],
                ),
                const SizedBox(height: 14),
                const ProgressBar(label: 'Overall Match', value: 82),
                const ProgressBar(label: 'Skills', value: 91),
                const ProgressBar(label: 'Experience', value: 76, color: AppColors.purple),
                const ProgressBar(label: 'Education', value: 100, color: AppColors.green),
                ProgressBar(label: 'Keywords', value: 73, color: AppColors.amber),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const SectionLabel('Strong Matches ✓'),
          const Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              AppChip(label: 'Flutter'),
              AppChip(label: 'Dart'),
              AppChip(label: 'REST APIs'),
              AppChip(label: 'Supabase'),
              AppChip(label: 'Git'),
              AppChip(label: 'Google Maps'),
            ],
          ),
          const SizedBox(height: 14),
          const SectionLabel('Missing Skills ✗'),
          const Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              AppChip(label: 'Docker', color: AppColors.red),
              AppChip(label: 'CI/CD', color: AppColors.red),
              AppChip(label: 'Unit Testing', color: AppColors.red),
            ],
          ),
          const SizedBox(height: 14),
          const InfoNote(
            icon: Icons.warning_amber_rounded,
            color: AppColors.amber,
            title: 'Weak Evidence',
            body: 'Testing experience is referenced in your Career DNA but lacks concrete project evidence to support it confidently.',
          ),
          const SizedBox(height: 14),
          const InfoNote(
            icon: Icons.lightbulb_outline_rounded,
            color: AppColors.purple,
            title: 'AI Recommendation',
            body: 'Your ShipLink project strongly supports the real-time systems requirement. Prioritize this in your CV summary.',
          ),
        ],
      ),
    );
  }
}

class _NewAnalysis extends StatelessWidget {
  const _NewAnalysis();

  static const _types = ['Full-time Job', 'Internship', "Master's", 'Scholarship'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Paste a job description, scholarship, or university program. The AI will extract requirements and match them against your Career DNA.',
            style: AppTextStyles.bodySub.copyWith(fontSize: 12, height: 1.6),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              maxLines: 8,
              minLines: 6,
              style: AppTextStyles.bodySub.copyWith(fontSize: 13, height: 1.6, color: AppColors.text),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
                hintText: 'Paste job description, internship listing, or program requirements here…',
                hintStyle: TextStyle(fontSize: 13, fontFamily: AppTextStyles.fontFamily, color: AppColors.textMuted),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _types)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cardHi,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(t, style: AppTextStyles.bodySmall),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt_rounded, size: 15, color: AppColors.background),
                SizedBox(width: 8),
                Text(
                  'Analyze with AI',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w700,
                    color: AppColors.background,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
