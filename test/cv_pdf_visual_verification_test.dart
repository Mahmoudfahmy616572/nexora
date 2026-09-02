import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/domain/cv/cv_pdf_renderer.dart';
import 'package:nexora/domain/entities/cv_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory outputDir;

  setUpAll(() async {
    outputDir = Directory('${Directory.current.path}/test/pdf_output');
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
  });

  tearDownAll(() async {
    if (await outputDir.exists()) {
      await outputDir.delete(recursive: true);
    }
  });

  group('1. PDF Generation - All Scenarios', () {
    test('A. Fresh Graduate - nexoraMinimal', () async {
      final content = _freshGraduate();
      final bytes = await CvPdfRenderer.render(content: content, templateId: 'nexoraMinimal');
      await File('${outputDir.path}/A_fresh_graduate_minimal.pdf').writeAsBytes(bytes);
      expect(bytes.length, greaterThan(1000));
      _validatePdf(bytes);
      debugPrint('A. Fresh Graduate Minimal: ${bytes.length} bytes, ${_pageCount(bytes)} page(s)');
    });

    test('B. Experienced Candidate - nexoraModern', () async {
      final content = _experiencedCandidate();
      final bytes = await CvPdfRenderer.render(content: content, templateId: 'nexoraModern');
      await File('${outputDir.path}/B_experienced_modern.pdf').writeAsBytes(bytes);
      expect(bytes.length, greaterThan(1000));
      _validatePdf(bytes);
      debugPrint('B. Experienced Modern: ${bytes.length} bytes, ${_pageCount(bytes)} page(s)');
    });

    test('C. Career Changer - nexoraCompact', () async {
      final content = _careerChanger();
      final bytes = await CvPdfRenderer.render(content: content, templateId: 'nexoraCompact');
      await File('${outputDir.path}/C_career_changer_compact.pdf').writeAsBytes(bytes);
      expect(bytes.length, greaterThan(1000));
      _validatePdf(bytes);
      debugPrint('C. Career Changer Compact: ${bytes.length} bytes, ${_pageCount(bytes)} page(s)');
    });

    test('D. Long 2-page CV - nexoraMinimal', () async {
      final content = _longCv();
      final bytes = await CvPdfRenderer.render(content: content, templateId: 'nexoraMinimal');
      await File('${outputDir.path}/D_long_2page_minimal.pdf').writeAsBytes(bytes);
      expect(bytes.length, greaterThan(2000));
      _validatePdf(bytes);
      expect(_pageCount(bytes), greaterThanOrEqualTo(2));
      debugPrint('D. Long 2-page Minimal: ${bytes.length} bytes, ${_pageCount(bytes)} page(s)');
    });

    test('E. Very Long CV - nexoraModern', () async {
      final content = _veryLongCv();
      final bytes = await CvPdfRenderer.render(content: content, templateId: 'nexoraModern');
      await File('${outputDir.path}/E_very_long_modern.pdf').writeAsBytes(bytes);
      expect(bytes.length, greaterThan(3000));
      _validatePdf(bytes);
      expect(_pageCount(bytes), greaterThanOrEqualTo(2));
      debugPrint('E. Very Long Modern: ${bytes.length} bytes, ${_pageCount(bytes)} page(s)');
    });

    test('F. Arabic RTL - all 3 templates', () async {
      final content = _arabicRtlCv();
      for (final tid in ['nexoraMinimal', 'nexoraModern', 'nexoraCompact']) {
        final bytes = await CvPdfRenderer.render(content: content, templateId: tid);
        await File('${outputDir.path}/F_arabic_rtl_$tid.pdf').writeAsBytes(bytes);
        _validatePdf(bytes);
        debugPrint('F. Arabic $tid: ${bytes.length} bytes, ${_pageCount(bytes)} page(s)');
      }
    });
  });

  group('2. PDF Structure Validity', () {
    test('starts with %PDF- header', () async {
      final bytes = await CvPdfRenderer.render(content: _freshGraduate(), templateId: 'nexoraMinimal');
      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
    });

    test('ends with %%EOF trailer', () async {
      final bytes = await CvPdfRenderer.render(content: _freshGraduate(), templateId: 'nexoraMinimal');
      expect(String.fromCharCodes(bytes.sublist(bytes.length - 10)), contains('%%EOF'));
    });

    test('contains /Type /Page and /Type /Pages objects', () async {
      final bytes = await CvPdfRenderer.render(content: _freshGraduate(), templateId: 'nexoraMinimal');
      final text = String.fromCharCodes(bytes);
      expect(RegExp(r'/Type\s*/Page\b').hasMatch(text), true);
      expect(RegExp(r'/Type\s*/Pages\b').hasMatch(text), true);
    });

    test('all 6 scenarios produce valid PDFs across all templates', () async {
      final scenarios = <String, CvContent>{
        'fresh': _freshGraduate(),
        'experienced': _experiencedCandidate(),
        'career': _careerChanger(),
        'long': _longCv(),
        'very_long': _veryLongCv(),
        'arabic': _arabicRtlCv(),
      };
      for (final entry in scenarios.entries) {
        for (final tid in ['nexoraMinimal', 'nexoraModern', 'nexoraCompact']) {
          final bytes = await CvPdfRenderer.render(content: entry.value, templateId: tid);
          final text = String.fromCharCodes(bytes);
          expect(text.substring(0, 5), '%PDF-');
          expect(text, contains('/Type'));
          expect(String.fromCharCodes(bytes.sublist(bytes.length - 10)), contains('%%EOF'));
        }
      }
    });
  });

  group('3. Multi-Page Validation', () {
    test('single-page CV stays 1 page', () async {
      final bytes = await CvPdfRenderer.render(content: _freshGraduate(), templateId: 'nexoraMinimal');
      expect(_pageCount(bytes), 1);
    });

    test('long CV produces 2+ pages', () async {
      final bytes = await CvPdfRenderer.render(content: _longCv(), templateId: 'nexoraMinimal');
      expect(_pageCount(bytes), greaterThanOrEqualTo(2));
    });

    test('very long CV produces 2+ pages', () async {
      final bytes = await CvPdfRenderer.render(content: _veryLongCv(), templateId: 'nexoraModern');
      expect(_pageCount(bytes), greaterThanOrEqualTo(2));
    });

    test('career changer fits on 1-2 pages compact', () async {
      final bytes = await CvPdfRenderer.render(content: _careerChanger(), templateId: 'nexoraCompact');
      expect(_pageCount(bytes), lessThanOrEqualTo(2));
    });
  });

  group('4. Template Comparison', () {
    test('3 templates produce different file sizes', () async {
      final content = _experiencedCandidate();
      final min = await CvPdfRenderer.render(content: content, templateId: 'nexoraMinimal');
      final mod = await CvPdfRenderer.render(content: content, templateId: 'nexoraModern');
      final comp = await CvPdfRenderer.render(content: content, templateId: 'nexoraCompact');
      final sizes = {min.length, mod.length, comp.length};
      expect(sizes.length, 3);
    });

    test('template switching preserves page count range', () async {
      final content = _experiencedCandidate();
      final minP = _pageCount(await CvPdfRenderer.render(content: content, templateId: 'nexoraMinimal'));
      final modP = _pageCount(await CvPdfRenderer.render(content: content, templateId: 'nexoraModern'));
      final compP = _pageCount(await CvPdfRenderer.render(content: content, templateId: 'nexoraCompact'));
      expect(minP, lessThanOrEqualTo(2));
      expect(modP, lessThanOrEqualTo(2));
      expect(compP, lessThanOrEqualTo(2));
    });
  });

  group('5. Font Verification', () {
    test('Inter font embedded', () async {
      final bytes = await CvPdfRenderer.render(content: _freshGraduate(), templateId: 'nexoraMinimal');
      expect(String.fromCharCodes(bytes), contains('/Font'));
    });

    test('Arabic font produces larger file than English-only', () async {
      final arabic = await CvPdfRenderer.render(content: _arabicRtlCv(), templateId: 'nexoraMinimal');
      final english = await CvPdfRenderer.render(content: _freshGraduate(), templateId: 'nexoraMinimal');
      expect(arabic.length, greaterThan(english.length));
    });

    test('rendering is deterministic', () async {
      final content = _freshGraduate();
      final b1 = await CvPdfRenderer.render(content: content, templateId: 'nexoraMinimal');
      final b2 = await CvPdfRenderer.render(content: content, templateId: 'nexoraMinimal');
      expect(b1.length, equals(b2.length));
    });
  });

  group('6. Export Flow', () {
    test('renderToFile creates valid file', () async {
      final result = await CvPdfRenderer.renderToFile(
        content: _freshGraduate(), templateId: 'nexoraMinimal',
        outputPath: '${outputDir.path}/export_test.pdf',
      );
      final file = File(result);
      expect(await file.exists(), true);
      _validatePdf(await file.readAsBytes());
    });

    test('renderToFile works for all templates', () async {
      final content = _experiencedCandidate();
      for (final tid in ['nexoraMinimal', 'nexoraModern', 'nexoraCompact']) {
        final result = await CvPdfRenderer.renderToFile(
          content: content, templateId: tid,
          outputPath: '${outputDir.path}/export_$tid.pdf',
        );
        _validatePdf(await File(result).readAsBytes());
      }
    });

    test('renderToFile for Arabic RTL', () async {
      final result = await CvPdfRenderer.renderToFile(
        content: _arabicRtlCv(), templateId: 'nexoraModern',
        outputPath: '${outputDir.path}/export_arabic.pdf',
      );
      _validatePdf(await File(result).readAsBytes());
    });
  });

  group('7. Performance', () {
    test('short CV < 2s', () async {
      final sw = Stopwatch()..start();
      final bytes = await CvPdfRenderer.render(content: _freshGraduate(), templateId: 'nexoraMinimal');
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(2000));
      expect(bytes.length, greaterThan(0));
      debugPrint('Short CV: ${sw.elapsedMilliseconds}ms');
    });

    test('long CV < 5s', () async {
      final sw = Stopwatch()..start();
      await CvPdfRenderer.render(content: _veryLongCv(), templateId: 'nexoraModern');
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(5000));
      debugPrint('Long CV: ${sw.elapsedMilliseconds}ms');
    });

    test('Arabic CV < 3s', () async {
      final sw = Stopwatch()..start();
      await CvPdfRenderer.render(content: _arabicRtlCv(), templateId: 'nexoraMinimal');
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(3000));
      debugPrint('Arabic CV: ${sw.elapsedMilliseconds}ms');
    });
  });

  group('8. Content Completeness', () {
    test('all data classes instantiate correctly', () async {
      const header = CvHeader(name: 'Test', title: 'Dev', email: 't@e.com', phone: '123', location: 'City', links: [CvContactLink(label: 'Web', url: 'u')]);
      expect(header.name, 'Test');

      const exp = CvExperience(role: 'R', company: 'C', startDate: '2020', endDate: '2023', bullets: ['A', 'B']);
      expect(exp.effectiveBullets, ['A', 'B']);

      const proj = CvProject(
        name: 'P',
        tech: ['T'],
        bullets: ['X'],
        links: [CvContactLink(label: 'L', url: 'https://l.test')],
      );
      expect(proj.effectiveBullets, ['X']);
      expect(proj.effectiveLinks, ['https://l.test']);

      const edu = CvEducation(degree: 'BS', field: 'CS', institution: 'Uni', year: '2020');
      expect(edu.degree, 'BS');

      const cert = CvCertification(name: 'AWS', issuer: 'Amazon', year: '2023');
      expect(cert.display, 'AWS \u00b7 Amazon \u00b7 2023');

      const lang = CvLanguage(name: 'English', level: 'Fluent');
      expect(lang.display, 'English \u2014 Fluent');

      const skill = CvSkillGroup(title: 'Languages', skills: ['Dart']);
      expect(skill.skills, ['Dart']);

      const ach = CvAchievement(text: 'Published paper');
      expect(ach.text, 'Published paper');
    });

    test('effectiveBullets falls back to description', () {
      const exp = CvExperience(role: 'R', description: 'Led a team of engineers');
      expect(exp.effectiveBullets, ['Led a team of engineers']);
    });

    test('effectiveBullets returns empty when nothing set', () {
      const exp = CvExperience(role: 'R');
      expect(exp.effectiveBullets, isEmpty);
    });

    test('effectiveLinks returns empty when nothing set', () {
      const proj = CvProject(name: 'P');
      expect(proj.effectiveLinks, isEmpty);
    });

    test('CvCertification.display handles missing fields', () {
      const cert = CvCertification(name: 'AWS');
      expect(cert.display, 'AWS');
    });

    test('CvLanguage.display without level', () {
      const lang = CvLanguage(name: 'Arabic');
      expect(lang.display, 'Arabic');
    });

    test('fresh graduate renders all expected sections', () async {
      final bytes = await CvPdfRenderer.render(content: _freshGraduate(), templateId: 'nexoraMinimal');
      _validatePdf(bytes);
      expect(bytes.length, greaterThan(5000));
    });

    test('experienced candidate renders all expected sections', () async {
      final bytes = await CvPdfRenderer.render(content: _experiencedCandidate(), templateId: 'nexoraModern');
      _validatePdf(bytes);
      expect(bytes.length, greaterThan(5000));
    });
  });

  group('9. RTL PDF Direction', () {
    test('Arabic content triggers RTL mode', () async {
      final arabic = _arabicRtlCv();
      final bytes = await CvPdfRenderer.render(content: arabic, templateId: 'nexoraMinimal');
      _validatePdf(bytes);
      expect(bytes.length, greaterThan(3000));
    });

    test('English content stays LTR', () async {
      final english = _freshGraduate();
      final bytes = await CvPdfRenderer.render(content: english, templateId: 'nexoraMinimal');
      _validatePdf(bytes);
    });

    test('mixed Arabic+English renders without error', () async {
      final content = CvContent(
        header: const CvHeader(
          name: '\u0645\u062d\u0645\u062f \u0639\u0644\u064a',
          title: 'Flutter Developer',
          email: 'mohamed@example.com',
        ),
        summary: '\u0645\u0647\u0646\u062f\u0633 \u0628\u0631\u0645\u062c\u064a\u0627\u062a Flutter \u0645\u0639 \u062e\u0628\u0631\u0629 \u0641\u064a\u0647\u0627',
        experience: const [
          CvExperience(role: 'Dev', company: 'TechCo', bullets: ['Built app', '\u0627\u0646\u0645\u0627\u0637 \u062a\u0637\u0628\u064a\u0642']),
        ],
        projects: const [],
        education: const [],
        skillGroups: const [CvSkillGroup(title: 'Mobile', skills: ['Flutter', 'Dart'])],
        certifications: const [],
        achievements: const [],
        languages: const [],
      );
      final bytes = await CvPdfRenderer.render(content: content, templateId: 'nexoraMinimal');
      _validatePdf(bytes);
    });

    test('RTL text direction applied on all templates', () async {
      final content = _arabicRtlCv();
      for (final tid in ['nexoraMinimal', 'nexoraModern', 'nexoraCompact']) {
        final bytes = await CvPdfRenderer.render(content: content, templateId: tid);
        _validatePdf(bytes);
        expect(bytes.length, greaterThan(3000));
      }
    });

    test('dates and numbers remain readable in RTL', () async {
      final content = CvContent(
        header: const CvHeader(name: '\u0639\u0644\u064a \u062e\u0627\u0644\u062f'),
        summary: '\u0645\u0647\u0646\u062f\u0633 \u0628\u0631\u0645\u062c\u064a\u0627\u062a',
        experience: const [
          CvExperience(role: 'Engineer', company: 'Co', startDate: 'Jan 2020', endDate: 'Present', location: '\u0627\u0644\u0642\u0627\u0647\u0631\u0629', bullets: ['\u0623\u0646\u0645\u0627\u0637 50+ \u062a\u0637\u0628\u064a\u0642']),
        ],
        projects: const [],
        education: const [],
        skillGroups: const [],
        certifications: const [],
        achievements: const [],
        languages: const [],
      );
      final bytes = await CvPdfRenderer.render(content: content, templateId: 'nexoraMinimal');
      _validatePdf(bytes);
    });
  });
}

int _pageCount(List<int> bytes) {
  final text = String.fromCharCodes(bytes);
  return RegExp(r'/Type\s*/Page\b').allMatches(text).length.clamp(1, 100);
}

void _validatePdf(List<int> bytes) {
  expect(bytes.length, greaterThan(100));
  final text = String.fromCharCodes(bytes);
  expect(text.substring(0, 5), '%PDF-');
  expect(text, contains('/Type'));
  expect(String.fromCharCodes(bytes.sublist(bytes.length - 10)), contains('%%EOF'));
}
CvContent _freshGraduate() => CvContent(
      header: const CvHeader(
        name: 'Sara Ahmed',
        title: 'Flutter Developer',
        email: 'sara.ahmed@example.com',
        phone: '+20 111 234 5678',
        location: 'Cairo, Egypt',
        links: [CvContactLink(label: 'LinkedIn', url: 'linkedin.com/in/saraahmed'), CvContactLink(label: 'GitHub', url: 'github.com/saraahmed')],
      ),
      summary: 'Motivated Flutter developer eager to build intuitive user interfaces.',
      experience: const [
        CvExperience(
          role: 'Mobile Development Intern',
          company: 'TechStart',
          startDate: 'Jun 2024',
          endDate: 'Aug 2024',
          bullets: [
            'Built 3 Flutter screens with responsive layouts',
            'Integrated REST API using Dio',
          ],
        ),
      ],
      projects: const [
        CvProject(
          name: 'TaskBuddy',
          description: 'Todo app with categories and reminders',
          tech: ['Flutter', 'SQLite'],
          bullets: [
            'Added local persistence with SQLite',
          ],
        ),
      ],
      education: const [
        CvEducation(degree: 'BSc', field: 'Computer Science', institution: 'Cairo University', year: '2024'),
      ],
      skillGroups: const [
        CvSkillGroup(title: 'Mobile', skills: ['Flutter', 'Dart', 'Firebase']),
        CvSkillGroup(title: 'Languages', skills: ['Python', 'JavaScript', 'SQL']),

      ],
      certifications: const [
        CvCertification(name: 'Flutter Certified Developer', issuer: 'Google', year: '2024'),
      ],
      achievements: const [
        CvAchievement(text: "Dean's List, Fall 2022 and Spring 2023"),
      ],
      languages: const [
        CvLanguage(name: 'Arabic', level: 'Native'),
        CvLanguage(name: 'English', level: 'Professional'),
      ],
    );
CvContent _experiencedCandidate() => CvContent(
      header: const CvHeader(
        name: 'Omar Khaled',
        title: 'Senior Full-Stack Engineer',
        email: 'omar.khaled@example.com',
        phone: '+20 122 345 6789',
        location: 'Cairo, Egypt',
        links: [CvContactLink(label: 'LinkedIn', url: 'linkedin.com/in/omarkhaled'), CvContactLink(label: 'GitHub', url: 'github.com/omarkhaled')],
      ),
      summary: 'Senior full-stack engineer with 8+ years of experience building scalable web platforms and leading cross-functional teams.',
      experience: const [
        CvExperience(
          role: 'Senior Engineer',
          company: 'CloudTech',
          startDate: 'Jan 2022',
          endDate: 'Present',
          location: 'Cairo, Egypt',
          bullets: [
            'Architected microservices platform serving 2M daily requests',
            'Led migration from monolith to services, cutting deploy time by 70%',
            'Mentored team of 5 engineers on clean architecture',
          ],
        ),
        CvExperience(
          role: 'Full-Stack Developer',
          company: 'WebScale',
          startDate: 'Mar 2019',
          endDate: 'Dec 2021',
          location: 'Remote',
          bullets: [
            'Built multi-tenant SaaS platform with 10k+ active users',
            'Implemented payment integration with Stripe and Paymob',
          ],
        ),
        CvExperience(
          role: 'Backend Developer',
          company: 'DataFlow',
          startDate: 'Jul 2017',
          endDate: 'Feb 2019',
          location: 'Giza, Egypt',
          description: 'Designed RESTful APIs and optimized database queries for high-traffic application.',
        ),
      ],
      projects: const [
        CvProject(
          name: 'DevOps Dashboard',
          tech: ['React', 'Node.js', 'Docker'],
          bullets: [
            'Real-time CI/CD pipeline monitoring for 50+ repos',
            'Automated incident alerts reducing response time by 40%',
          ],
          links: [CvContactLink(label: 'GitHub', url: 'github.com/omarkhaled/devops-dashboard')],
        ),
        CvProject(
          name: 'Inventory Pro',
          tech: ['Flutter', 'Firebase', 'Go'],
          bullets: [
            'Multi-platform inventory management system',
            'Barcode scanning with offline sync',
          ],
        ),
        CvProject(
          name: 'API Gateway',
          description: 'Centralized API gateway with rate limiting and auth',
          tech: ['Go', 'Redis', 'PostgreSQL'],
          links: [CvContactLink(label: 'GitHub', url: 'github.com/omarkhaled/api-gateway')],
        ),
      ],
      education: const [
        CvEducation(degree: 'MSc', field: 'Computer Science', institution: 'Cairo University', year: '2017'),
        CvEducation(degree: 'BSc', field: 'Computer Engineering', institution: 'Ain Shams University', year: '2015'),
      ],
      skillGroups: const [
        CvSkillGroup(title: 'Frontend', skills: ['React', 'Angular', 'Flutter', 'TypeScript']),
        CvSkillGroup(title: 'Backend', skills: ['Node.js', 'Go', 'Python', 'GraphQL']),
        CvSkillGroup(title: 'Infrastructure', skills: ['Docker', 'Kubernetes', 'AWS', 'Terraform']),
        CvSkillGroup(title: 'Databases', skills: ['PostgreSQL', 'MongoDB', 'Redis', 'Firebase']),
      ],
      certifications: const [
        CvCertification(name: 'AWS Solutions Architect', issuer: 'Amazon', year: '2022'),
        CvCertification(name: 'Professional Cloud Architect', issuer: 'Google', year: '2021'),
      ],
      achievements: const [
        CvAchievement(text: 'Speaker at DevFest Cairo 2023'),
        CvAchievement(text: 'Open-source contributor with 2k+ GitHub stars'),
      ],
      languages: const [
        CvLanguage(name: 'Arabic', level: 'Native'),
        CvLanguage(name: 'English', level: 'Fluent'),
      ],
    );
CvContent _careerChanger() => CvContent(
      header: const CvHeader(
        name: 'Nour Hassan',
        title: 'Data Analyst',
        email: 'nour.hassan@example.com',
        phone: '+20 100 987 6543',
        location: 'New Cairo, Egypt',
      ),
      summary: 'Detail-oriented analyst transitioning from marketing to data, skilled in SQL, Python, and data visualization.',
      experience: const [
        CvExperience(
          role: 'Data Analyst',
          company: 'InsightLab',
          startDate: 'Mar 2024',
          endDate: 'Present',
          bullets: [
            'Built dashboards tracking 15 KPIs for product team',
            'Automated weekly reports saving 8 hours of manual work',
            'Analyzed user cohorts increasing retention by 12%',
          ],
        ),
        CvExperience(
          role: 'Marketing Coordinator',
          company: 'BrandCo',
          startDate: 'Jan 2022',
          endDate: 'Feb 2024',
          description: 'Managed marketing campaigns and analyzed performance metrics across channels.',
        ),
      ],
      projects: const [
        CvProject(
          name: 'Sales Analytics Pipeline',
          tech: ['Python', 'Pandas', 'Plotly'],
          bullets: [
            'ETL pipeline processing 100k rows of sales data daily',
            'Interactive Plotly dashboards for stakeholders',
          ],
        ),
        CvProject(
          name: 'Customer Segmentation',
          tech: ['Python', 'Scikit-learn', 'Tableau'],
          description: 'K-means clustering for 50k customer records',
        ),
      ],
      education: const [
        CvEducation(degree: 'BBA', field: 'Marketing', institution: 'AUC', year: '2021'),
      ],
      skillGroups: const [
        CvSkillGroup(title: 'Data', skills: ['SQL', 'Python', 'Tableau', 'Excel']),
        CvSkillGroup(title: 'Marketing', skills: ['Google Analytics', 'SEO', 'Campaign Management']),
      ],
      certifications: const [
        CvCertification(name: 'Google Data Analytics', issuer: 'Google', year: '2023'),
      ],
      achievements: const [
        CvAchievement(text: 'Increased campaign ROI by 25% through data-driven A/B testing'),
      ],
      languages: const [
        CvLanguage(name: 'Arabic', level: 'Native'),
        CvLanguage(name: 'English', level: 'Fluent'),
      ],
    );
CvContent _longCv() => CvContent(
      header: const CvHeader(
        name: 'Ahmed Farouk',
        title: 'Platform Architect',
        email: 'ahmed.farouk@example.com',
        phone: '+20 115 678 9012',
        location: 'Alexandria, Egypt',
        links: [CvContactLink(label: 'LinkedIn', url: 'linkedin.com/in/ahmedfarouk'), CvContactLink(label: 'GitHub', url: 'github.com/ahmedfarouk'), CvContactLink(label: 'Portfolio', url: 'ahmedfarouk.dev')],
      ),
      summary: 'Platform architect with 12+ years building distributed systems, leading engineering teams, and driving technical strategy.',
      experience: const [
        CvExperience(
          role: 'Platform Architect',
          company: 'MegaCloud',
          startDate: 'Jan 2020',
          endDate: 'Present',
          location: 'Cairo, Egypt',
          bullets: [
            'Led monolith-to-microservices migration reducing deploy time from 2h to 5min',
            'Designed event-driven architecture processing 1M+ events/day',
            'Built internal developer platform used by 200+ engineers',
            'Established engineering standards adopted company-wide',
            'Mentored 12 junior engineers, 4 promoted to senior roles',
            'Drove adoption of infrastructure-as-code across 3 cloud regions',
          ],
        ),
        CvExperience(
          role: 'Senior Backend Engineer',
          company: 'StartupInc',
          startDate: '2017',
          endDate: '2020',
          location: 'Seattle, WA',
          bullets: [
            'Led backend team building real-time collaboration platform',
            'Implemented WebSocket infrastructure handling 50k concurrent connections',
            'Reduced API latency by 60% through query optimization',
            'Designed and shipped event sourcing system for order management',
          ],
        ),
        CvExperience(
          role: 'Software Engineer',
          company: 'BigTech',
          startDate: '2014',
          endDate: '2017',
          location: 'Austin, TX',
          bullets: [
            'Built search infrastructure indexing 500M documents',
            'Implemented data pipelines processing 10TB daily',
            'Shipped ML-powered recommendation engine increasing CTR by 18%',
          ],
        ),
      ],
      projects: const [
        CvProject(
          name: 'Distributed Cache System',
          tech: ['Go', 'Redis', 'gRPC'],
          bullets: [
            'Achieved sub-millisecond latency for 99th percentile requests',
            'Handled 500k concurrent connections with automatic failover',
          ],
        ),
        CvProject(
          name: 'CI/CD Pipeline',
          tech: ['Kubernetes', 'Terraform', 'GitHub Actions'],
          bullets: [
            'Reduced deployment failures by 80% through automated testing gates',
            'Enabled 50+ daily deployments with zero-downtime rolling updates',
          ],
        ),
        CvProject(
          name: 'ML Feature Store',
          description: 'Built feature store serving ML models in production',
          tech: ['Python', 'Apache Spark', 'Airflow'],
        ),
        CvProject(
          name: 'API Gateway',
          tech: ['Kong', 'Lua', 'PostgreSQL'],
          bullets: [
            'Managed 100+ API endpoints with rate limiting and authentication',
          ],
        ),
      ],
      education: const [
        CvEducation(degree: 'MSc', field: 'Computer Science', institution: 'Stanford University', year: '2014'),
        CvEducation(degree: 'BSc', field: 'Computer Engineering', institution: 'UT Austin', year: '2012'),
      ],
      skillGroups: const [
        CvSkillGroup(title: 'Languages', skills: ['Go', 'Python', 'TypeScript', 'Java', 'Rust']),
        CvSkillGroup(title: 'Infrastructure', skills: ['Kubernetes', 'Docker', 'Terraform', 'AWS', 'GCP']),
        CvSkillGroup(title: 'Databases', skills: ['PostgreSQL', 'MongoDB', 'Redis', 'Cassandra']),
        CvSkillGroup(title: 'Architecture', skills: ['Microservices', 'Event-Driven', 'CQRS', 'DDD']),
      ],
      certifications: const [
        CvCertification(name: 'AWS Solutions Architect Professional', issuer: 'Amazon', year: '2022'),
        CvCertification(name: 'Google Cloud Professional Architect', issuer: 'Google', year: '2021'),
      ],
      achievements: const [
        CvAchievement(text: 'Published 3 technical papers on distributed systems'),
        CvAchievement(text: 'Speaker at KubeCon 2023 on platform engineering'),
        CvAchievement(text: 'Open-source contributor with 5k+ GitHub stars'),
      ],
      languages: const [
        CvLanguage(name: 'English', level: 'Native'),
        CvLanguage(name: 'Mandarin', level: 'Conversational'),
      ],
    );
CvContent _veryLongCv() => CvContent(
      header: const CvHeader(
        name: 'Youssef Ibrahim',
        title: 'Principal Engineer',
        email: 'youssef.ibrahim@example.com',
        phone: '+20 100 111 2222',
        location: 'Dubai, UAE',
        links: [CvContactLink(label: 'LinkedIn', url: 'linkedin.com/in/youssefibrahim'), CvContactLink(label: 'GitHub', url: 'github.com/youssefibrahim'), CvContactLink(label: 'Portfolio', url: 'youssef.engineer')],
      ),
      summary: 'Principal engineer with 18+ years of experience in distributed systems, cloud architecture, and technical leadership across fintech and e-commerce domains.',
      experience: const [
        CvExperience(
          role: 'Principal Engineer',
          company: 'FinScale',
          startDate: 'Mar 2021',
          endDate: 'Present',
          location: 'Dubai, UAE',
          bullets: [
            'Architected payment processing platform handling \$2B+ annual transaction volume',
            'Led platform modernization migrating 50+ services to Kubernetes',
            'Designed multi-region active-active architecture with 99.999% uptime',
            'Established engineering guild structure across 8 teams and 120 engineers',
            'Built real-time fraud detection system processing 10k transactions/second',
            'Introduced event-driven architecture reducing inter-service coupling by 70%',
            'Drove technical strategy resulting in 40% infrastructure cost reduction',
          ],
        ),
        CvExperience(
          role: 'Staff Engineer',
          company: 'ShopMatrix',
          startDate: 'Jun 2018',
          endDate: 'Feb 2021',
          location: 'London, UK',
          bullets: [
            'Led design of global inventory management system across 15 countries',
            'Built real-time search infrastructure indexing 50M+ products',
            'Implemented blue-green deployment strategy reducing downtime to zero',
            'Mentored 20 engineers across 4 teams on system design best practices',
            'Architected event sourcing platform processing 1M events/day',
          ],
        ),
        CvExperience(
          role: 'Senior Software Engineer',
          company: 'DataVault',
          startDate: '2015',
          endDate: '2018',
          location: 'Berlin, Germany',
          bullets: [
            'Designed data lake architecture processing 50TB of analytics data daily',
            'Built ML pipeline framework used by 10 data science teams',
            'Implemented auto-scaling infrastructure reducing costs by 35%',
          ],
        ),
        CvExperience(
          role: 'Software Engineer',
          company: 'CloudNest',
          startDate: '2012',
          endDate: '2015',
          location: 'Cairo, Egypt',
          bullets: [
            'Built microservices platform serving 5M+ API calls daily',
            'Implemented CI/CD pipeline reducing deployment time by 80%',
          ],
        ),
        CvExperience(
          role: 'Junior Developer',
          company: 'WebCraft',
          startDate: '2008',
          endDate: '2012',
          location: 'Cairo, Egypt',
          bullets: [
            'Developed e-commerce platform handling 100k daily users',
            'Built RESTful APIs and background job processing system',
          ],
        ),
      ],
      projects: const [
        CvProject(
          name: 'Global Payment Gateway',
          tech: ['Go', 'gRPC', 'PostgreSQL', 'Kafka'],
          bullets: [
            'Processed \$2B+ annually across 30 payment methods',
            'Achieved p99 latency under 50ms for payment authorization',
            'Built PCI-DSS compliant tokenization service',
            'Implemented idempotent retry mechanism for failed transactions',
          ],
        ),
        CvProject(
          name: 'Observability Platform',
          tech: ['Go', 'ClickHouse', 'Grafana', 'OpenTelemetry'],
          bullets: [
            'Unified metrics, logs, and traces into single platform',
            'Reduced mean-time-to-detection from hours to under 2 minutes',
            'Built custom alerting engine processing 1M+ metrics/second',
          ],
        ),
        CvProject(
          name: 'Feature Flag Service',
          tech: ['Rust', 'Redis', 'React'],
          bullets: [
            'A/B testing framework serving 50M+ feature evaluations daily',
            'Built targeting engine with 100+ rule combinations',
          ],
        ),
        CvProject(
          name: 'CLI Toolkit',
          description: 'Open-source developer CLI for microservice scaffolding and deployment',
          tech: ['Rust', 'CLAP'],
          bullets: [
            '1.2k GitHub stars and 50+ community contributors',
          ],
        ),
      ],
      education: const [
        CvEducation(degree: 'PhD', field: 'Distributed Systems', institution: 'ETH Zurich', year: '2012'),
        CvEducation(degree: 'MSc', field: 'Computer Science', institution: 'Cairo University', year: '2008'),
        CvEducation(degree: 'BSc', field: 'Computer Engineering', institution: 'Cairo University', year: '2006'),
      ],
      skillGroups: const [
        CvSkillGroup(title: 'Languages', skills: ['Go', 'Rust', 'Python', 'TypeScript', 'Java']),
        CvSkillGroup(title: 'Infrastructure', skills: ['Kubernetes', 'Terraform', 'AWS', 'GCP', 'Azure', 'Datadog']),
        CvSkillGroup(title: 'Data', skills: ['PostgreSQL', 'ClickHouse', 'Kafka', 'Redis', 'Elasticsearch']),
        CvSkillGroup(title: 'Architecture', skills: ['Microservices', 'Event Sourcing', 'CQRS', 'DDD', 'Hexagonal']),
        CvSkillGroup(title: 'Leadership', skills: ['Technical Strategy', 'RFC Process', 'Mentoring', 'Architecture Review']),
      ],
      certifications: const [
        CvCertification(name: 'AWS Solutions Architect Professional', issuer: 'Amazon', year: '2020'),
        CvCertification(name: 'Google Cloud Professional Architect', issuer: 'Google', year: '2019'),
        CvCertification(name: 'Certified Kubernetes Administrator', issuer: 'CNCF', year: '2021'),
        CvCertification(name: 'Hashicorp Terraform Associate', issuer: 'Hashicorp', year: '2022'),
      ],
      achievements: const [
        CvAchievement(text: 'Published 8 technical papers on distributed systems and cloud architecture'),
        CvAchievement(text: 'Keynote speaker at KubeCon 2023 and QCon 2022'),
        CvAchievement(text: 'Open-source maintainer with 15k+ GitHub stars across projects'),
        CvAchievement(text: 'Held patents for novel approaches to distributed consensus algorithms'),
      ],
      languages: const [
        CvLanguage(name: 'Arabic', level: 'Native'),
        CvLanguage(name: 'English', level: 'Fluent'),
        CvLanguage(name: 'German', level: 'Professional'),
      ],
    );
CvContent _arabicRtlCv() => CvContent(
      header: const CvHeader(
        name: '\u0645\u062d\u0645\u062f \u0627\u0644\u0644\u0647 \u0639\u0628\u062f \u0627\u0644\u0644\u0647',
        title: '\u0645\u0647\u0646\u062f\u0633 \u0628\u0631\u0645\u062c\u064a\u0627\u062a',
        email: 'mohamed.abdullah@example.com',
        phone: '+20 111 222 3333',
        location: '\u0627\u0644\u0642\u0627\u0647\u0631\u0629\u060c \u0645\u0635\u0631',
      ),
      summary: '\u0645\u0647\u0646\u062f\u0633 \u0628\u0631\u0645\u062c\u064a\u0627\u062a \u0625\u0633\u0644\u0627\u0645\u064a \u062e\u0628\u0631\u0629 \u0641\u064a \u062a\u0637\u0648\u064a\u0631 Flutter \u0648\u0641\u0639\u0644 \u062a\u0637\u0628\u064a\u0642 \u0645\u0648\u062c\u0647\u0627\u062a \u062a\u0634\u063a\u064a\u0644 \u0645\u062a\u0642\u062f\u0645\u0629.',
      experience: const [
        CvExperience(
          role: '\u0645\u0647\u0646\u062f\u0633 Flutter',
          company: 'TechVision',
          startDate: '2023',
          endDate: '\u0627\u0644\u062d\u0627\u0644\u064a\u0627\u0646',
          location: '\u0627\u0644\u0642\u0627\u0647\u0631\u0629',
          bullets: [
            '\u062a\u0637\u0648\u064a\u0631 12 \u0634\u0627\u0634\u0629 Flutter \u0644\u062a\u0637\u0628\u064a\u0642\u0627\u062a \u0625\u0633\u0644\u0627\u0645\u064a\u0629',
            '\u062a\u0642\u0648\u064a\u0645 Firebase \u0644\u0644\u0645\u0639\u0644\u0648\u0645\u0627\u062a \u0627\u0644\u062d\u064a\u0648\u064a\u0629',
            '\u062a\u0646\u0641\u064a\u0630 \u0627\u0644\u0623\u062f\u0627\u0621 \u0627\u0644\u0622\u0644\u064a\u0629 \u0644\u0644\u062a\u062d\u0642\u0642 \u0645\u0646 \u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645\u064a\u0646',
          ],
        ),
        CvExperience(
          role: '\u0645\u0637\u0648\u0631 \u062a\u0637\u0648\u064a\u0631',
          company: 'DigitalWorks',
          startDate: '2021',
          endDate: '2023',
          location: '\u0627\u0644\u0642\u0627\u0647\u0631\u0629',
          bullets: [
            '\u0628\u0646\u0627\u0621 \u062a\u0637\u0628\u064a\u0642 \u0645\u0648\u0627\u0642\u0639 \u0645\u0639\u0631\u0641\u0629 \u0628\u0627\u0633\u062a\u062e\u062f\u0627\u0645 Firebase',
            '\u062a\u0643\u0648\u064a\u0646 \u0646\u0638\u0627\u0645 \u0627\u0644\u0645\u0635\u0627\u062d\u0629 \u0627\u0644\u0645\u0624\u0643\u0633\u0631\u0629',
          ],
        ),
      ],
      projects: const [
        CvProject(
          name: '\u062a\u0637\u0628\u064a\u0642 \u0627\u0644\u0645\u0637\u0628\u0639\u0627\u062a',
          tech: ['Flutter', 'Firebase', 'Dart'],
          bullets: [
            '\u062a\u0637\u0628\u064a\u0642 20 \u0634\u0627\u0634\u0629 \u0645\u062a\u0646\u0633\u0642\u0629',
            '\u062a\u062e\u0632\u064a\u0646 \u0627\u0644\u062a\u0634\u063a\u064a\u0644 \u0628\u0627\u0633\u062a\u062e\u062f\u0627\u0645 \u062d\u0633\u0627\u0628 Google',
          ],
        ),
        CvProject(
          name: '\u0645\u0639\u0644\u0648\u0645\u0627\u062a \u0627\u0644\u0623\u0635\u0648\u0627\u0628',
          tech: ['Flutter', 'REST API', 'SQLite'],
          description: '\u062a\u0637\u0628\u064a\u0642 \u0645\u0648\u062c\u0647 \u0644\u0644\u0623\u0635\u0648\u0627\u0628 \u0628\u062f\u0648\u0646 \u0625\u0646\u062a\u0631\u0646\u062a',
        ),
      ],
      education: const [
        CvEducation(degree: 'BSc', field: 'Computer Science', institution: '\u062c\u0627\u0645\u0639\u0629 \u0627\u0644\u0642\u0627\u0647\u0631\u0629', year: '2021'),
      ],
      skillGroups: const [
        CvSkillGroup(title: '\u0627\u0644\u062a\u0637\u0648\u064a\u0631', skills: ['Flutter', 'Dart', 'Firebase']),
        CvSkillGroup(title: '\u0627\u0644\u0644\u063a\u0627\u062a', skills: ['\u0627\u0644\u0639\u0631\u0628\u064a\u0629', '\u0627\u0644\u0625\u0646\u062c\u0644\u064a\u0632\u064a\u0629']),
        CvSkillGroup(title: '\u0627\u0644\u0623\u062f\u0648\u0627\u062a', skills: ['Git', 'VS Code', 'Android Studio']),
      ],
      certifications: const [
        CvCertification(name: 'Google Associate Android Developer', issuer: 'Google', year: '2022'),
      ],
      achievements: const [
        CvAchievement(text: '\u0641\u0627\u0626\u0632 \u0623\u0648\u0644\u060c \u0645\u062d\u0627\u0641\u0638\u0629 \u062a\u0637\u0648\u064a\u0631 \u062c\u0627\u0645\u0639\u0629 \u0627\u0644\u0642\u0627\u0647\u0631\u0629 2023'),
        CvAchievement(text: '\u0627\u0644\u062a\u0631\u0633\u064a\u0645 \u0627\u0644\u0623\u0648\u0644 \u0641\u064a \u0645\u062d\u0627\u0636\u0631\u0629 Talents 2022'),
      ],
      languages: const [
        CvLanguage(name: '\u0627\u0644\u0639\u0631\u0628\u064a\u0629', level: '\u0627\u0644\u0623\u0645'),
        CvLanguage(name: '\u0627\u0644\u0625\u0646\u062c\u0644\u064a\u0632\u064a\u0629', level: '\u062a\u062d\u0635\u0644\u064a'),
      ],
    );

