import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/data/data_sources/career_local_data_source.dart';
import 'package:nexora/data/repositories/cv_suggestion_repository_impl.dart';
import 'package:nexora/domain/entities/cv_evaluation.dart';
import 'package:shared_preferences/shared_preferences.dart';

CvSuggestion _suggestion(String id, String evaluationId, CvSuggestionStatus status) =>
    CvSuggestion(
      id: id,
      userId: 'u',
      evaluationId: evaluationId,
      versionId: 'v',
      section: 'summary',
      problem: 'p',
      current: '',
      suggested: 'x',
      why: 'w',
      targetRequirement: '',
      status: status,
      createdAt: DateTime.now(),
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('save, load by evaluation, and update persist locally', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = CvSuggestionRepositoryImpl(CareerLocalDataSource(prefs));

    final saved = await repo.saveSuggestion(
      _suggestion('1', 'e1', CvSuggestionStatus.pending),
    );
    expect(saved.id, '1');

    final loaded = await repo.loadByEvaluation('e1');
    expect(loaded.length, 1);

    final updated = saved.copyWith(
      status: CvSuggestionStatus.accepted,
      editedText: 'edited',
    );
    await repo.updateSuggestion(updated);

    final reloaded = await repo.loadByEvaluation('e1');
    expect(reloaded.first.status, CvSuggestionStatus.accepted);
    expect(reloaded.first.editedText, 'edited');
  });

  test('loadByEvaluation scopes to the evaluation id', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = CvSuggestionRepositoryImpl(CareerLocalDataSource(prefs));

    await repo.saveSuggestion(_suggestion('a', 'eA', CvSuggestionStatus.pending));
    await repo.saveSuggestion(_suggestion('b', 'eB', CvSuggestionStatus.pending));

    expect((await repo.loadByEvaluation('eA')).length, 1);
    expect((await repo.loadByEvaluation('eB')).length, 1);
  });

  test('deleteForEvaluation removes only that evaluation', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = CvSuggestionRepositoryImpl(CareerLocalDataSource(prefs));

    await repo.saveSuggestion(_suggestion('a', 'eA', CvSuggestionStatus.pending));
    await repo.saveSuggestion(_suggestion('b', 'eB', CvSuggestionStatus.pending));
    await repo.deleteForEvaluation('eA');

    expect((await repo.loadByEvaluation('eA')).length, 0);
    expect((await repo.loadByEvaluation('eB')).length, 1);
  });
}
