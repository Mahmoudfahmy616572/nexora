import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nexora/data/data_sources/career_local_data_source.dart';
import 'package:nexora/data/data_sources/career_remote_data_source.dart';
import 'package:nexora/data/repositories/career_repository_impl.dart';
import 'package:nexora/domain/entities/cv_profile.dart';
import 'package:nexora/domain/entities/job_analysis.dart';
import 'package:nexora/domain/entities/job_application.dart';
import 'package:nexora/domain/entities/profile_data.dart';
import 'package:nexora/domain/entities/profile_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('career repositories fall back to local storage', () {
    test('load returns null when nothing has been stored anywhere', () async {
      final repo = JobApplicationRepositoryImpl(
        CareerRemoteDataSource(),
        CareerLocalDataSource(await SharedPreferences.getInstance()),
      );

      expect(await repo.load(), isNull);
    });

    test('saveAll then load round-trips through local storage', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = JobApplicationRepositoryImpl(
        CareerRemoteDataSource(),
        CareerLocalDataSource(prefs),
      );
      const apps = [
        JobApplication(id: 'a', company: 'Google', role: 'Flutter Engineer', status: 'Interview', date: 'Aug 17', match: 91, ats: 92),
        JobApplication(id: 'b', company: 'Careem', role: 'Mobile Developer', status: 'Under Review', date: 'Aug 10', match: 82, ats: 87),
      ];

      await repo.saveAll(apps);

      final loaded = await repo.load();
      expect(loaded, hasLength(2));
      expect(loaded![0].company, 'Google');
      expect(loaded[0].status, 'Interview');
      expect(loaded[1].role, 'Mobile Developer');
      expect(prefs.getStringList('tracker.apps'), hasLength(2));
    });

    test('load skips malformed entries and keeps the valid ones', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = JobApplicationRepositoryImpl(
        CareerRemoteDataSource(),
        CareerLocalDataSource(prefs),
      );
      const good = JobApplication(id: 'g', company: 'Noon', role: 'Frontend', status: 'Applied', date: 'Aug 1', match: 70, ats: 74);
      await prefs.setStringList('tracker.apps', [
        jsonEncode(good.toJson()),
        'not-json',
        jsonEncode({'id': 'x'}), // missing required fields
      ]);

      final loaded = await repo.load();
      expect(loaded, hasLength(1));
      expect(loaded![0].company, 'Noon');
    });

    test('an empty stored list survives as an empty list', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = JobApplicationRepositoryImpl(
        CareerRemoteDataSource(),
        CareerLocalDataSource(prefs),
      );
      await prefs.setStringList('tracker.apps', []);

      expect(await repo.load(), isEmpty);
    });

    test('all four feature repositories persist under their own keys', () async {
      final prefs = await SharedPreferences.getInstance();
      final local = CareerLocalDataSource(prefs);
      final remote = CareerRemoteDataSource();

      await CvRepositoryImpl(remote, local).saveAll([
        const CvProfile(id: 'cv1', title: 'Flutter Engineer', ats: 89, purpose: 'Job', updated: 'Aug 8', match: 82),
      ]);
      await JobAnalysisRepositoryImpl(remote, local).saveAll([
        const JobAnalysis(id: 'an1', title: 'Flutter Engineer', company: 'Careem', timeAgo: '2h ago', overall: 82, skills: 91, experience: 76, education: 100, keywords: 73, strong: ['Flutter'], missing: ['Docker']),
      ]);
      await ProfileSectionRepositoryImpl(remote, local).saveAll([
        const ProfileSection(id: 'sec1', label: 'Volunteering', pct: 0, category: 'v'),
      ]);

      expect(prefs.getStringList('studio.cvs'), hasLength(1));
      expect(prefs.getStringList('analyze.analyses'), hasLength(1));
      expect(prefs.getStringList('dna.custom.sections'), hasLength(1));
      expect(await CvRepositoryImpl(remote, local).load(), hasLength(1));
      expect(await JobAnalysisRepositoryImpl(remote, local).load(), hasLength(1));
      expect(await ProfileSectionRepositoryImpl(remote, local).load(), hasLength(1));
    });

    test('analyze throws when Supabase is unavailable so screens can fall back', () async {
      final repo = JobAnalysisRepositoryImpl(
        CareerRemoteDataSource(),
        CareerLocalDataSource(await SharedPreferences.getInstance()),
      );

      await expectLater(
        repo.analyze(
          description: 'Flutter Engineer with 3+ years',
          skills: const ['Flutter'],
        ),
        throwsA(anything),
      );
    });

    test('profile skills round-trip through local storage', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = ProfileSkillsRepositoryImpl(
        CareerRemoteDataSource(),
        CareerLocalDataSource(prefs),
      );

      expect(await repo.load(), isNull);
      await repo.save(const ['Flutter', 'Dart', 'Supabase']);
      expect(await repo.load(), ['Flutter', 'Dart', 'Supabase']);
      expect(prefs.getStringList('dna.skills'), ['Flutter', 'Dart', 'Supabase']);
    });

    test('real profile data round-trips through local storage', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = ProfileRepositoryImpl(
        CareerRemoteDataSource(),
        CareerLocalDataSource(prefs),
      );

      expect(await repo.load(), isNull);

      const profile = ProfileData(
        summary: 'Flutter engineer shipping real-time products.',
        experience: [
          ProfileExperience(role: 'Senior Flutter Engineer', company: 'Careem', years: 3),
        ],
        projects: [
          ProfileProject(name: 'ShipLink', description: 'Live tracking app', tech: ['Flutter', 'Dart']),
        ],
        education: [ProfileEducation(degree: 'B.Sc. Computer Engineering', field: 'Software')],
        certifications: ['AWS Certified Developer'],
        achievements: ['1st place, Hackathon 2025'],
        languages: ['Arabic (Native)', 'English (Fluent)'],
      );

      await repo.save(profile);
      final loaded = await repo.load();
      expect(loaded, isNotNull);
      expect(loaded!.summary, profile.summary);
      expect(loaded.experience.single.role, 'Senior Flutter Engineer');
      expect(loaded.experience.single.years, 3);
      expect(loaded.yearsTotal, 3);
      expect(loaded.projects.single.tech, ['Flutter', 'Dart']);
      expect(loaded.education.single.degree, 'B.Sc. Computer Engineering');
      expect(loaded.certifications, ['AWS Certified Developer']);
      expect(loaded.achievements, ['1st place, Hackathon 2025']);
      expect(loaded.languages, ['Arabic (Native)', 'English (Fluent)']);
      expect(prefs.getString('profile.content'), isNotNull);
    });
  });
}
