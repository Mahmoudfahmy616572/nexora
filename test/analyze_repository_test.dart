import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nexora/data/data_sources/career_local_data_source.dart';
import 'package:nexora/data/data_sources/career_remote_data_source.dart';
import 'package:nexora/data/repositories/career_repository_impl.dart';
import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/career_target.dart';
import 'package:nexora/domain/entities/job_analysis.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<JobAnalysisRepositoryImpl> makeRepo() async => JobAnalysisRepositoryImpl(
        CareerRemoteDataSource(),
        CareerLocalDataSource(await SharedPreferences.getInstance()),
      );

  CareerTarget sampleTarget() => CareerTarget(
        id: 'target-1',
        userId: 'u',
        type: TargetType.job,
        role: 'Mobile Lead',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

  test('analyze falls back to the offline engine and produces detail', () async {
    final repo = await makeRepo();
    final result = await repo.analyze(
      description: 'Flutter Engineer with 3+ years and a Bachelor degree.',
      dna: CareerDna(skills: const ['Flutter']),
    );

    expect(result, isA<JobAnalysis>());
    expect(result.detail, isNotNull);
    expect(result.detail!.overall, inInclusiveRange(0, 100));
    expect(result.detail!.role, isNotEmpty);
  });

  test('analyze records the provided target id', () async {
    final repo = await makeRepo();
    final result = await repo.analyze(
      description: 'Flutter Engineer with 3+ years.',
      dna: CareerDna(skills: const ['Flutter']),
      target: sampleTarget(),
    );

    expect(result.targetId, 'target-1');
    expect(result.detail!.targetId, 'target-1');
  });

  test('analyzed result round-trips through saveAll/load', () async {
    final repo = await makeRepo();
    final result = await repo.analyze(
      description: 'Backend developer, 2+ years, Python and AWS.',
      dna: CareerDna(skills: const ['Python']),
    );

    await repo.saveAll([result]);
    final loaded = await repo.load();
    expect(loaded, isNotNull);
    expect(loaded!.any((a) => a.id == result.id), isTrue);
    expect(loaded.firstWhere((a) => a.id == result.id).detail, isNotNull);
  });

  test('missing candidate data still yields an analysis (all-unclear)', () async {
    final repo = await makeRepo();
    final result = await repo.analyze(
      description: 'Senior Rust Engineer, 5+ years.',
      dna: CareerDna(),
    );

    expect(result.detail, isNotNull);
    expect(result.detail!.overall, inInclusiveRange(0, 100));
  });
}
