import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/data/data_sources/career_local_data_source.dart';
import 'package:nexora/data/data_sources/career_remote_data_source.dart';
import 'package:nexora/data/repositories/cv_evaluation_repository_impl.dart';
import 'package:nexora/data/repositories/cv_suggestion_repository_impl.dart';
import 'package:nexora/domain/entities/cv_content.dart';
import 'package:nexora/domain/entities/cv_evaluation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remote that fails like the AI edge function being unavailable offline.
class _FailingRemote extends CareerRemoteDataSource {
  @override
  Future<Map<String, dynamic>> runCvEvaluate(Map<String, dynamic> input) async {
    throw Exception('simulated AI failure');
  }
}

CvContent _content() => const CvContent(
      header: CvHeader(name: 'Jane'),
      summary: 'Flutter engineer.',
      experience: [CvExperience(role: 'Dev', company: 'Acme', years: 3)],
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('evaluate stays deterministic and labelled deterministicOnly '
      'when the AI step is unavailable', () async {
    final prefs = await SharedPreferences.getInstance();
    final local = CareerLocalDataSource(prefs);
    final suggestionRepo = CvSuggestionRepositoryImpl(local);
    final repo = CvEvaluationRepositoryImpl(
      _FailingRemote(),
      local,
      suggestionRepo,
    );

    final result = await repo.evaluate(
      content: _content(),
      userId: 'u',
      versionId: 'v1',
      targetId: 't1',
    );

    expect(result.evaluation.deterministicOnly, isTrue);
    expect(result.evaluation.overall, inInclusiveRange(0, 100));
    expect(result.suggestions, isA<List<CvSuggestion>>());

    // The evaluation and its suggestions were persisted locally.
    final loaded = await repo.loadEvaluation('v1');
    expect(loaded, isNotNull);
    expect(loaded!.deterministicOnly, isTrue);
    final stored = await suggestionRepo.loadByEvaluation(result.evaluation.id);
    expect(stored.length, result.suggestions.length);
  });

  test('saveEvaluation upserts by id', () async {
    final prefs = await SharedPreferences.getInstance();
    final local = CareerLocalDataSource(prefs);
    final suggestionRepo = CvSuggestionRepositoryImpl(local);
    final repo = CvEvaluationRepositoryImpl(
      _FailingRemote(),
      local,
      suggestionRepo,
    );
    final e = CvEvaluation(
      id: 'e2',
      userId: 'u',
      versionId: 'v2',
      targetId: 't2',
      overall: 50,
      ats: 50,
      targetAlignment: 50,
      contentStrength: 50,
      evidenceStrength: 50,
      readability: 50,
      clarity: 50,
      structure: 50,
      keywordAlignment: 50,
      skillAlignment: 50,
      sectionCompleteness: 50,
      explanations: const {},
      deterministicOnly: true,
      createdAt: DateTime.now(),
    );
    await repo.saveEvaluation(e);
    await repo.saveEvaluation(e.copyWith(overall: 60));
    final loaded = await repo.loadEvaluation('v2');
    expect(loaded!.overall, 60);
  });
}
