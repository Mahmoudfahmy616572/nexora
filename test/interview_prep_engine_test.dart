import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/domain/analysis/interview_prep_engine.dart';
import 'package:nexora/domain/entities/opportunity_analysis.dart';

JobRequirement _req(String label, bool required, RequirementStatus status) =>
    JobRequirement(
      label: label,
      required: required,
      status: status,
      evidenceSource: EvidenceSource.none,
    );

OpportunityAnalysis _analysis(List<JobRequirement> reqs) => OpportunityAnalysis(
      requirements: reqs,
    );

void main() {
  group('InterviewPrepEngine.selectFocusAreas', () {
    test('orders required gaps, then partial, then mismatches', () {
      final analysis = _analysis([
        _req('Flutter', true, RequirementStatus.strongMatch), // excluded
        _req('Rust', true, RequirementStatus.notEvidenced), // required gap
        _req('Kotlin', false, RequirementStatus.partialMatch), // preferred gap
        _req('5yr exp', true, RequirementStatus.requirementMismatch), // mismatch
      ]);
      final focus = InterviewPrepEngine.selectFocusAreas(analysis);
      // '5yr exp' is a *required* mismatch, so it lands in requiredGaps before
      // the preferred partial 'Kotlin'.
      expect(focus, ['Rust', '5yr exp', 'Kotlin']);
    });

    test('de-duplicates by label and excludes strong matches', () {
      final analysis = _analysis([
        _req('Flutter', true, RequirementStatus.strongMatch),
        _req('Flutter', true, RequirementStatus.notEvidenced),
        _req('Dart', true, RequirementStatus.notEvidenced),
      ]);
      final focus = InterviewPrepEngine.selectFocusAreas(analysis);
      expect(focus, ['Flutter', 'Dart']);
    });

    test('caps to maxAreas', () {
      final analysis = _analysis([
        for (var i = 0; i < 10; i++)
          _req('Skill$i', true, RequirementStatus.notEvidenced),
      ]);
      final focus = InterviewPrepEngine.selectFocusAreas(analysis, maxAreas: 6);
      expect(focus.length, 6);
    });

    test('returns empty for null analysis', () {
      expect(InterviewPrepEngine.selectFocusAreas(null), isEmpty);
    });
  });

  group('InterviewPrepEngine.rationaleFor', () {
    test('uses evidence text when present', () {
      final analysis = _analysis([
        JobRequirement(
          label: 'Flutter',
          required: true,
          status: RequirementStatus.notEvidenced,
          evidenceSource: EvidenceSource.none,
          evidenceText: 'No Flutter project found in your DNA.',
        ),
      ]);
      expect(
        InterviewPrepEngine.rationaleFor(analysis, 'Flutter'),
        'No Flutter project found in your DNA.',
      );
    });

    test('falls back to a status-based rationale', () {
      final analysis = _analysis([
        _req('Rust', true, RequirementStatus.notEvidenced),
      ]);
      final why = InterviewPrepEngine.rationaleFor(analysis, 'Rust');
      expect(why, contains('Career DNA'));
    });

    test('returns empty for unknown requirement', () {
      final analysis = _analysis([_req('Flutter', true, RequirementStatus.strongMatch)]);
      expect(InterviewPrepEngine.rationaleFor(analysis, 'Nope'), '');
    });
  });

  group('InterviewPrepEngine.focusFromSkills', () {
    test('de-duplicates skills and caps', () {
      final focus = InterviewPrepEngine.focusFromSkills(
        ['Dart', 'Dart', 'Flutter', 'Rust'],
        maxAreas: 2,
      );
      expect(focus, ['Dart', 'Flutter']);
    });
  });
}
