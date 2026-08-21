import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/domain/entities/opportunity_analysis.dart';

void main() {
  group('JobRequirement', () {
    test('two requirements with the same fields are equal', () {
      const a = JobRequirement(
        label: 'Flutter',
        required: true,
        status: RequirementStatus.strongMatch,
        evidenceSource: EvidenceSource.declaredSkill,
        evidenceText: 'Declared skill: flutter',
      );
      const b = JobRequirement(
        label: 'Flutter',
        required: true,
        status: RequirementStatus.strongMatch,
        evidenceSource: EvidenceSource.declaredSkill,
        evidenceText: 'Declared skill: flutter',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('props expose all fields', () {
      const r = JobRequirement(
        label: 'AWS',
        required: false,
        status: RequirementStatus.partialMatch,
        evidenceSource: EvidenceSource.project,
        evidenceText: 'Project X',
      );

      expect(r.props, contains('AWS'));
      expect(r.props, contains(RequirementStatus.partialMatch));
    });
  });

  group('OpportunityAnalysis', () {
    const sample = OpportunityAnalysis(
      targetId: 't1',
      jobDescription: 'JD',
      role: 'Flutter Engineer',
      company: 'Careem',
      seniority: 'Senior',
      requirements: [
        JobRequirement(
          label: 'Flutter',
          required: true,
          status: RequirementStatus.strongMatch,
          evidenceSource: EvidenceSource.declaredSkill,
          evidenceText: 'Declared skill: flutter',
        ),
        JobRequirement(
          label: 'AWS',
          required: false,
          status: RequirementStatus.partialMatch,
          evidenceSource: EvidenceSource.declaredSkill,
          evidenceText: 'Related skill: GCP (adjacent to aws).',
        ),
        JobRequirement(
          label: 'PhD',
          required: true,
          status: RequirementStatus.requirementMismatch,
          evidenceSource: EvidenceSource.none,
          evidenceText: 'Requires PhD; you hold Bachelor.',
        ),
        JobRequirement(
          label: 'Rust',
          required: true,
          status: RequirementStatus.notEvidenced,
          evidenceSource: EvidenceSource.none,
          evidenceText: 'No evidence found in your Career DNA.',
        ),
        JobRequirement(
          label: 'GraphQL',
          required: false,
          status: RequirementStatus.unknown,
          evidenceSource: EvidenceSource.none,
          evidenceText: 'Not enough data in your Career DNA to evaluate this.',
        ),
      ],
      responsibilities: ['Ship'],
      technologies: ['Flutter'],
      experienceItem: JobRequirement(
        label: 'Experience',
        required: true,
        status: RequirementStatus.strongMatch,
        evidenceSource: EvidenceSource.professionalExperience,
        evidenceText: '5 yrs professional experience',
      ),
      educationItem: JobRequirement(
        label: 'Education',
        required: true,
        status: RequirementStatus.requirementMismatch,
        evidenceSource: EvidenceSource.none,
        evidenceText: 'Requires Master; you hold Bachelor.',
      ),
      experienceRequirement: '5+ years',
      educationRequirement: 'Bachelor',
      certifications: ['CKAD'],
      languages: ['Arabic'],
      softSkills: ['Communication'],
      domainKnowledge: ['Fintech'],
      keywords: ['Flutter', 'Rust'],
      skillsScore: 80,
      experienceScore: 100,
      educationScore: 45,
      keywordsScore: 50,
      languageScore: 100,
      overall: 78,
      recommendationCategory: MatchCategory.good,
      recommendationText: 'Good match — apply after closing a few preferred gaps.',
    );

    test('round-trips through JSON', () {
      final json = sample.toJson();
      final restored = OpportunityAnalysis.fromJson(json);

      expect(restored.targetId, sample.targetId);
      expect(restored.role, sample.role);
      expect(restored.requirements.length, sample.requirements.length);
      expect(restored.overall, sample.overall);
      expect(restored.recommendationCategory, sample.recommendationCategory);
      expect(restored.experienceRequirement, sample.experienceRequirement);
      expect(restored.educationRequirement, sample.educationRequirement);
      expect(restored.skillsScore, sample.skillsScore);
    });

    test('derived getters classify requirements', () {
      expect(sample.strongMatches.map((r) => r.label), contains('Flutter'));
      expect(sample.partialMatches.map((r) => r.label), contains('AWS'));
      expect(sample.requirementMismatches.map((r) => r.label), contains('PhD'));
      expect(sample.notEvidenced.map((r) => r.label), contains('Rust'));
      expect(sample.unknowns.map((r) => r.label), contains('GraphQL'));
    });

    test('evidenceMap is keyed by requirement label', () {
      final map = sample.evidenceMap;
      expect(map['Flutter'], isNotNull);
      expect(map['Rust'], isNotNull);
      expect(map['Flutter']!.status, RequirementStatus.strongMatch);
    });
  });
}
