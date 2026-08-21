import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/domain/entities/job_extraction.dart';

void main() {
  group('JobExtraction serialization', () {
    test('round-trips through JSON', () {
      const ext = JobExtraction(
        role: 'Flutter Engineer',
        company: 'Careem',
        requiredSkills: ['Flutter', 'Dart'],
        preferredSkills: ['AWS'],
        responsibilities: ['Ship features'],
        technologies: ['Flutter', 'Firebase'],
        experienceYearsRequired: 3,
        educationRequired: 'bachelor',
        certifications: ['CKAD'],
        languages: ['Arabic'],
        softSkills: ['Communication'],
        domainKnowledge: ['Fintech'],
        keywords: ['Flutter', 'Dart', 'AWS'],
        seniority: 'Senior',
        locationRemote: 'remote',
        rawText: 'Full JD text.',
      );

      final json = ext.toJson();
      final restored = JobExtraction.fromJson(json);

      expect(restored.role, ext.role);
      expect(restored.requiredSkills, ext.requiredSkills);
      expect(restored.preferredSkills, ext.preferredSkills);
      expect(restored.responsibilities, ext.responsibilities);
      expect(restored.technologies, ext.technologies);
      expect(restored.experienceYearsRequired, ext.experienceYearsRequired);
      expect(restored.educationRequired, ext.educationRequired);
      expect(restored.certifications, ext.certifications);
      expect(restored.languages, ext.languages);
      expect(restored.softSkills, ext.softSkills);
      expect(restored.domainKnowledge, ext.domainKnowledge);
      expect(restored.keywords, ext.keywords);
      expect(restored.seniority, ext.seniority);
      expect(restored.locationRemote, ext.locationRemote);
      expect(restored.rawText, ext.rawText);
    });

    test('handles missing fields via fromJson', () {
      final restored = JobExtraction.fromJson(const <String, dynamic>{});
      expect(restored.requiredSkills, isEmpty);
      expect(restored.experienceYearsRequired, isNull);
      expect(restored.role, isEmpty);
    });
  });
}
