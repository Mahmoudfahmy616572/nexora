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
}
