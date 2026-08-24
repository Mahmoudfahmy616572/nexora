import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nexora/data/data_sources/career_local_data_source.dart';
import 'package:nexora/data/data_sources/career_remote_data_source.dart';
import 'package:nexora/data/repositories/career_repository_impl.dart';
import 'package:nexora/domain/entities/interview_practice_session.dart';
import 'package:nexora/domain/repositories/interview_practice_repository.dart';

InterviewPracticeRepository _repo(SharedPreferences prefs) =>
    InterviewPracticeRepositoryImpl(
      CareerRemoteDataSource(),
      CareerLocalDataSource(prefs),
    );

InterviewPracticeSession _session({
  required String id,
  required DateTime startedAt,
  List<InterviewPracticeTurn> turns = const [],
  int overall = 0,
}) =>
    InterviewPracticeSession(
      id: id,
      userId: 'u',
      role: 'Flutter Dev',
      company: 'Acme',
      startedAt: startedAt,
      status: PracticeStatus.completed,
      overallScore: overall,
      turns: turns,
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('save then loadRecent returns newest first, capped by limit', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = _repo(prefs);

    await repo.save(_session(
      id: 'old',
      startedAt: DateTime.utc(2026, 1, 1),
      overall: 50,
    ));
    await repo.save(_session(
      id: 'new',
      startedAt: DateTime.utc(2026, 2, 1),
      overall: 80,
    ));

    final recent = await repo.loadRecent(1);
    expect(recent, hasLength(1));
    expect(recent.first.id, 'new');

    final all = await repo.loadRecent(10);
    expect(all, hasLength(2));
    expect(all.first.id, 'new');
    expect(all.last.id, 'old');
  });

  test('loadById returns the matching session or null', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = _repo(prefs);

    await repo.save(_session(id: 'a', startedAt: DateTime.utc(2026, 1, 1)));
    await repo.save(_session(id: 'b', startedAt: DateTime.utc(2026, 1, 2)));

    expect((await repo.loadById('b'))?.id, 'b');
    expect(await repo.loadById('missing'), isNull);
  });

  test('delete removes only the target session', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = _repo(prefs);

    await repo.save(_session(id: 'a', startedAt: DateTime.utc(2026, 1, 1)));
    await repo.save(_session(id: 'b', startedAt: DateTime.utc(2026, 1, 2)));

    await repo.delete('a');
    final remaining = await repo.loadRecent(10);
    expect(remaining, hasLength(1));
    expect(remaining.first.id, 'b');
  });

  test('turns are persisted and round-trip through JSON', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = _repo(prefs);

    final turn = InterviewPracticeTurn(
      id: 't1',
      question: 'Design a cache.',
      answer: 'I used system design to build an LRU cache.',
      focusArea: 'System design',
      relevanceScore: 100,
      specificityScore: 60,
      structureScore: 80,
      profileConsistencyScore: 100,
      compositeScore: 88,
      verdict: PracticeVerdict.good,
      feedbackStrengths: const ['Strong structure'],
      feedbackImprove: const ['Add a metric'],
      coachingSketch: 'Practice STAR.',
      unverifiedClaims: const [],
      createdAt: DateTime.utc(2026, 1, 1, 12),
    );
    await repo.save(_session(
      id: 's',
      startedAt: DateTime.utc(2026, 1, 1),
      turns: [turn],
    ));

    final loaded = await repo.loadById('s');
    expect(loaded?.turns, hasLength(1));
    final rt = loaded!.turns.first;
    expect(rt.question, 'Design a cache.');
    expect(rt.compositeScore, 88);
    expect(rt.verdict, PracticeVerdict.good);
    expect(rt.feedbackStrengths, ['Strong structure']);
  });
}
