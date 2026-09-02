import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/domain/entities/cv_content.dart';

void main() {
  test('toJson/fromJson round-trips structured content', () {
    final c = CvContent(
      header: const CvHeader(name: 'A', email: 'a@b.com'),
      summary: 'S',
      experience: const [CvExperience(role: 'R', company: 'C', years: 2)],
      projects: const [CvProject(name: 'P', tech: ['Flutter'])],
      education: const [CvEducation(degree: 'BSc')],
      skillGroups: const [CvSkillGroup(title: 'Skills', skills: ['Dart'])],
      certifications: const [CvCertification(name: 'C1')],
      achievements: const [CvAchievement(text: 'A1')],
      languages: const [CvLanguage(name: 'English')],
      sourceLabel: 'Factual CV',
    );
    final back = CvContent.fromJson(c.toJson());
    expect(back.header.name, 'A');
    expect(back.experience.first.years, 2);
    expect(back.projects.first.tech, ['Flutter']);
    expect(back.sourceLabel, 'Factual CV');
  });

  test('copyWith only changes provided fields', () {
    final c = CvContent(summary: 'old');
    final n = c.copyWith(summary: 'new');
    expect(n.summary, 'new');
    expect(c.summary, 'old');
  });

  test('yearsLabel formats nullable years', () {
    expect(const CvExperience(role: 'r').yearsLabel, '');
    expect(const CvExperience(role: 'r', years: 3).yearsLabel, '3y');
  });

  test('display getters combine fields', () {
    expect(const CvCertification(name: 'C', issuer: 'I', year: '2020').display,
        'C · I · 2020');
    expect(const CvLanguage(name: 'English', level: 'Fluent').display,
        'English — Fluent');
    expect(const CvLanguage(name: 'Arabic').display, 'Arabic');
  });

  test('header copyWith', () {
    final h = const CvHeader(name: 'A').copyWith(email: 'x@y.z');
    expect(h.name, 'A');
    expect(h.email, 'x@y.z');
  });

  group('CvExperience bullets', () {
    test('bullets field round-trips through toJson/fromJson', () {
      const e = CvExperience(
        role: 'Dev',
        company: 'ACME',
        bullets: ['Built the app', 'Integrated APIs'],
      );
      final back = CvExperience.fromJson(e.toJson());
      expect(back.bullets, ['Built the app', 'Integrated APIs']);
      expect(back.description, '');
    });

    test('effectiveBullets returns bullets when present', () {
      const e = CvExperience(
        role: 'Dev',
        bullets: ['Bullet 1', 'Bullet 2'],
      );
      expect(e.effectiveBullets, ['Bullet 1', 'Bullet 2']);
    });

    test('effectiveBullets falls back to description', () {
      const e = CvExperience(
        role: 'Dev',
        description: 'Did some work',
      );
      expect(e.effectiveBullets, ['Did some work']);
    });

    test('effectiveBullets returns empty when both empty', () {
      const e = CvExperience(role: 'Dev');
      expect(e.effectiveBullets, isEmpty);
    });

    test('backward compat: old format without bullets key', () {
      final old = CvExperience.fromJson({
        'role': 'Dev',
        'company': 'Co',
        'description': 'Built stuff',
      });
      expect(old.bullets, ['Built stuff']);
      expect(old.effectiveBullets, ['Built stuff']);
    });

    test('backward compat: empty description produces no bullets', () {
      final old = CvExperience.fromJson({
        'role': 'Dev',
        'company': 'Co',
      });
      expect(old.bullets, isEmpty);
      expect(old.effectiveBullets, isEmpty);
    });
  });

  group('CvProject bullets and links', () {
    test('bullets field round-trips through toJson/fromJson', () {
      const p = CvProject(
        name: 'App',
        bullets: ['Built UI', 'Added auth'],
        tech: ['Flutter'],
      );
      final back = CvProject.fromJson(p.toJson());
      expect(back.bullets, ['Built UI', 'Added auth']);
      expect(back.description, '');
    });

    test('effectiveBullets returns bullets when present', () {
      const p = CvProject(name: 'App', bullets: ['B1', 'B2']);
      expect(p.effectiveBullets, ['B1', 'B2']);
    });

    test('effectiveBullets falls back to description', () {
      const p = CvProject(name: 'App', description: 'A delivery app');
      expect(p.effectiveBullets, ['A delivery app']);
    });

    test('effectiveLinks returns urls when present', () {
      const p = CvProject(
        name: 'App',
        links: [
          CvContactLink(label: 'GitHub', url: 'https://github.com/app'),
          CvContactLink(label: 'Demo', url: 'https://demo.app'),
        ],
      );
      expect(p.effectiveLinks, ['https://github.com/app', 'https://demo.app']);
    });

    test('links round-trip through toJson/fromJson', () {
      const p = CvProject(
        name: 'App',
        links: [
          CvContactLink(label: 'GitHub', url: 'https://github.com/app'),
        ],
      );
      final back = CvProject.fromJson(p.toJson());
      expect(back.links.length, 1);
      expect(back.links.first.label, 'GitHub');
      expect(back.links.first.url, 'https://github.com/app');
    });

    test('effectiveLinks returns empty when none', () {
      const p = CvProject(name: 'App');
      expect(p.effectiveLinks, isEmpty);
    });

    test('role field round-trips', () {
      const p = CvProject(name: 'App', role: 'Founder');
      final back = CvProject.fromJson(p.toJson());
      expect(back.role, 'Founder');
    });

    test('date field round-trips', () {
      const p = CvProject(name: 'App', date: '2024');
      final back = CvProject.fromJson(p.toJson());
      expect(back.date, '2024');
    });

    test('backward compat: old format without bullets key', () {
      final old = CvProject.fromJson({
        'name': 'App',
        'description': 'Built a delivery app',
        'tech': ['Flutter'],
      });
      expect(old.bullets, ['Built a delivery app']);
      expect(old.effectiveBullets, ['Built a delivery app']);
    });
  });

  group('CvExperience location', () {
    test('location round-trips', () {
      const e = CvExperience(role: 'Dev', location: 'Cairo, Egypt');
      final back = CvExperience.fromJson(e.toJson());
      expect(back.location, 'Cairo, Egypt');
    });
  });
}
