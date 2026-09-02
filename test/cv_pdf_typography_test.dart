import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/domain/cv/cv_pdf_renderer.dart';
import 'package:nexora/domain/cv/cv_section_ordering.dart';
import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/career_target.dart';
import 'package:nexora/domain/entities/cv_content.dart';

const _templates = ['nexoraMinimal', 'nexoraModern', 'nexoraCompact'];

final _richContent = CvContent(
  header: CvHeader(
    name: 'Layla Haddad',
    title: 'Flutter Developer',
    email: 'layla@example.com',
    phone: '+49 170 000 000',
    location: 'Berlin, DE',
    links: [CvContactLink(label: 'GitHub', url: 'github.com/layla')],
  ),
  summary:
      'Mobile engineer focused on shipping polished Flutter products. '
      'Comfortable across the stack from Firebase rules to native channels.',
  experience: [
    CvExperience(
      role: 'Mobile Engineer',
      company: 'Acme GmbH',
      startDate: 'Jan 2022',
      endDate: 'Present',
      location: 'Berlin',
      bullets: [
        'Led the migration of the checkout flow to a modular architecture.',
        'Cut cold-start time by 38% through deferred component loading.',
        'Mentored two junior engineers on testing practices.',
      ],
    ),
    CvExperience(
      role: 'Junior Developer',
      company: 'Startuply',
      startDate: 'Jun 2020',
      endDate: 'Dec 2021',
      bullets: [
        'Built the internal admin dashboard used by 40 staff.',
      ],
    ),
  ],
  projects: [
    CvProject(
      name: 'Trackly',
      role: 'Creator',
      tech: ['Flutter', 'Supabase', 'Edge Functions'],
      links: [CvContactLink(label: 'GitHub', url: 'github.com/layla/trackly')],
      bullets: [
        'Habit tracker with offline-first sync and 4.8 star rating.',
        'Open source with 300+ GitHub stars.',
      ],
    ),
  ],
  education: [
    CvEducation(
      degree: 'BSc',
      field: 'Computer Science',
      institution: 'TU Berlin',
      year: '2020',
    ),
  ],
  skillGroups: [
    CvSkillGroup(title: 'Languages', skills: ['Dart', 'Python', 'SQL']),
    CvSkillGroup(title: 'Frameworks', skills: ['Flutter', 'FastAPI']),
  ],
  certifications: [
    CvCertification(name: 'AWS Cloud Practitioner', issuer: 'Amazon', year: '2023'),
  ],
  achievements: [
    CvAchievement(text: 'First place, Berlin Mobile Hackathon 2022.'),
  ],
  languages: [
    CvLanguage(name: 'Arabic', level: 'Native'),
    CvLanguage(name: 'English', level: 'C1'),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF type scale hierarchy', () {
    for (final id in _templates) {
      test('$id enforces name > title >= section > body > meta', () {
        final s = CvPdfRenderer.typeScaleFor(id);
        expect(s.nameSize, greaterThan(s.titleSize));
        expect(s.titleSize, greaterThanOrEqualTo(s.sectionTitleSize));
        expect(s.titleSize, greaterThan(s.bodySize));
        expect(s.sectionTitleSize, greaterThanOrEqualTo(s.bodySize * 0.88),
            reason: '$id caps section titles stay close to body size');
        expect(s.bodySize, greaterThan(s.metaSize));
        expect(s.nameTracking, greaterThan(0));
        expect(s.sectionTracking, greaterThan(0));
      });
    }

    test('template personalities produce distinct scales', () {
      final minimal = CvPdfRenderer.typeScaleFor('nexoraMinimal');
      final modern = CvPdfRenderer.typeScaleFor('nexoraModern');
      final compact = CvPdfRenderer.typeScaleFor('nexoraCompact');

      expect(minimal.nameSize, greaterThan(modern.nameSize));
      expect(modern.nameSize, greaterThan(compact.nameSize));
      expect(compact.bodySize, lessThan(minimal.bodySize));
      expect(minimal.marginH, greaterThan(compact.marginH));
    });

    test('margins and rhythm stay inside print-safe bounds', () {
      for (final id in _templates) {
        final s = CvPdfRenderer.typeScaleFor(id);
        expect(s.marginH, inInclusiveRange(36, 56),
            reason: '$id horizontal margin');
        expect(s.marginV, inInclusiveRange(28, 52), reason: '$id vertical margin');
        expect(s.itemGap, greaterThan(s.bulletGap), reason: id);
        expect(s.headerGap, greaterThan(s.sectionGap * 0.8), reason: id);
        expect(s.skillCategoryWidth, inInclusiveRange(80, 120), reason: id);
        expect(s.markerWidth, inInclusiveRange(6, 14), reason: id);
        expect(s.bodyLead, greaterThanOrEqualTo(s.bodySize * 0.25), reason: id);
      }
    });
  });

  group('PDF composition integration', () {
    test('rich multi-section CV exports a valid PDF on every template',
        () async {
      for (final id in _templates) {
        final bytes = await CvPdfRenderer.render(content: _richContent, templateId: id);
        expect(bytes.length, greaterThan(5000), reason: id);
        expect(String.fromCharCodes(bytes.take(8)), startsWith('%PDF'), reason: id);
      }
    });

    test('bold weight glyphs come from a real Inter-Bold embedded font',
        () async {
      final bytes =
          await CvPdfRenderer.render(content: _richContent, templateId: 'nexoraModern');
      final raw = String.fromCharCodes(bytes);
      expect(raw.contains('/BaseFont/Inter-Bold'), isTrue,
          reason: 'Inter-Bold must be embedded for headings');
    });

    test('medium/semibold weights are embedded alongside bold', () async {
      final bytes =
          await CvPdfRenderer.render(content: _richContent, templateId: 'nexoraCompact');
      final raw = String.fromCharCodes(bytes);
      expect(raw.contains('/BaseFont/Inter-SemiBold'), isTrue,
          reason: 'project/company emphasis uses SemiBold');
      expect(raw.contains('/BaseFont/Inter-Medium'), isTrue,
          reason: 'role lines use Medium');
    });
  });

  group('target-aware section ordering reaches the PDF pipeline', () {
    test('fresh graduate leads with projects before experience', () {
      final sections = CvSectionOrdering.orderedSectionsForStages(
        content: _richContent,
        stage: CareerStage.freshGraduate,
      );
      expect(sections.indexOf(CvSection.projects),
          lessThan(sections.indexOf(CvSection.experience)));
    });

    test('career changer leads with skills before experience', () {
      final sections = CvSectionOrdering.orderedSectionsForStages(
        content: _richContent,
        stage: CareerStage.careerChanger,
      );
      expect(sections.indexOf(CvSection.skills),
          lessThan(sections.indexOf(CvSection.experience)));
    });

    test('academic target leads with education', () {
      final sections = CvSectionOrdering.orderedSectionsForStages(
        content: _richContent,
        targetType: TargetType.academicApplication,
      );
      expect(sections.first, CvSection.summary);
      expect(sections[1], CvSection.education);
    });

    test('default keeps experience first and drops empty sections', () {
      final sparse = CvContent(header: CvHeader(name: 'X'));
      final sections =
          CvSectionOrdering.orderedSectionsForStages(content: sparse);
      expect(sections, isEmpty);
      final withExp = _richContent.copyWith(
        projects: const [],
        education: const [],
      );
      final ordered =
          CvSectionOrdering.orderedSectionsForStages(content: withExp);
      expect(ordered.first, CvSection.summary);
      expect(ordered[1], CvSection.experience);
      expect(ordered.contains(CvSection.projects), isFalse);
      expect(ordered.contains(CvSection.education), isFalse);
    });

    test('render() accepts stage/targetType without breaking output',
        () async {
      final bytes = await CvPdfRenderer.render(
        content: _richContent,
        templateId: 'nexoraMinimal',
        stage: CareerStage.freshGraduate,
        targetType: TargetType.internship,
      );
      expect(String.fromCharCodes(bytes.take(8)), startsWith('%PDF'));
    });
  });
}
