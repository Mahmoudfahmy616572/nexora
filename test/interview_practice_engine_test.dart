import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/domain/entities/interview_practice_session.dart';
import 'package:nexora/domain/practice/interview_practice_engine.dart';

void main() {
  group('InterviewPracticeEngine.assess (deterministic scoring)', () {
    const known = {'dart', 'flutter', 'system', 'design'};

    test('empty answer scores 0 relevance', () {
      final a = InterviewPracticeEngine.assess(
        answer: '',
        question: 'Q',
        focusArea: 'System design',
        knownTerms: known,
      );
      expect(a.relevanceScore, 0);
      expect(a.verdict, PracticeVerdict.needsImprovement);
    });

    test('answer covering the focus-area concepts scores high relevance', () {
      final a = InterviewPracticeEngine.assess(
        answer: 'I used system design to design a scalable service.',
        question: 'Q',
        focusArea: 'System design',
        knownTerms: known,
      );
      expect(a.relevanceScore, 100);
    });

    test('answer with metrics scores high specificity', () {
      final a = InterviewPracticeEngine.assess(
        answer: 'I increased engagement by 20% and reduced churn by 10%.',
        question: 'Q',
        focusArea: 'Metrics',
        knownTerms: known,
      );
      expect(a.specificityScore, greaterThanOrEqualTo(60));
    });

    test('answer without metrics scores 0 specificity', () {
      final a = InterviewPracticeEngine.assess(
        answer: 'I tried to make it better for the users.',
        question: 'Q',
        focusArea: 'Metrics',
        knownTerms: known,
      );
      expect(a.specificityScore, 0);
    });

    test('STAR-structured answer scores high structure', () {
      final a = InterviewPracticeEngine.assess(
        answer: 'When we launched the app, I led the migration which '
            'improved performance by 40%.',
        question: 'Q',
        focusArea: 'Leadership',
        knownTerms: known,
      );
      expect(a.structureScore, 100);
    });

    test('known skill keeps profile consistency at 100', () {
      final a = InterviewPracticeEngine.assess(
        answer: 'I built it in Flutter.',
        question: 'Q',
        focusArea: 'Flutter',
        knownTerms: known,
      );
      expect(a.profileConsistencyScore, 100);
      expect(a.unverifiedClaims, isEmpty);
    });

    test('unverified claim lowers consistency and is flagged (never judged)', () {
      final a = InterviewPracticeEngine.assess(
        answer: 'I deployed the service with Kubernetes.',
        question: 'Q',
        focusArea: 'DevOps',
        knownTerms: known,
      );
      expect(a.profileConsistencyScore, lessThan(100));
      expect(a.unverifiedClaims, contains('Kubernetes'));
    });

    test('composite is the weighted average in 0..100', () {
      final a = InterviewPracticeEngine.assess(
        answer: 'When the deadline came, I led the API rewrite which '
            'increased throughput by 35% using Flutter.',
        question: 'Q',
        focusArea: 'System design',
        knownTerms: known,
      );
      expect(a.compositeScore, inInclusiveRange(0, 100));
      expect(a.verdict, isA<PracticeVerdict>());
    });
  });

  group('InterviewPracticeEngine.buildQueue', () {
    test('caps to maxQuestions and de-duplicates', () {
      final questions = [
        for (var i = 0; i < 8; i++)
          PracticeQuestion(requirement: 'Area $i', questionText: 'Q$i'),
      ];
      final queue = InterviewPracticeEngine.buildQueue(
        questions,
        overflow: const ['Extra'],
      );
      expect(queue.length, 5);
      final texts = queue.map((q) => q.questionText).toSet();
      expect(texts.length, queue.length);
    });

    test('fills up to the minimum from overflow', () {
      final queue = InterviewPracticeEngine.buildQueue(
        const [PracticeQuestion(requirement: 'A', questionText: 'A')],
        overflow: const ['E1', 'E2', 'E3', 'E4', 'E5'],
        minQuestions: 3,
      );
      expect(queue.length, 5);
    });
  });

  group('InterviewPracticeEngine.summarize', () {
    test('aggregates scores and recommends the weakest area', () {
      final turnA = _turn(focusArea: 'A', composite: 90);
      final turnB = _turn(focusArea: 'B', composite: 40);
      final session = InterviewPracticeSession(
        id: 's1',
        userId: 'u',
        startedAt: DateTime(2024),
        turns: [turnA, turnB],
      );
      final result = InterviewPracticeEngine.summarize(session);
      expect(result.status, PracticeStatus.completed);
      expect(result.overallScore, 65);
      expect(result.recommendedNextArea, 'B');
    });

    test('empty session is returned unchanged', () {
      final session = InterviewPracticeSession(
        id: 's1',
        userId: 'u',
        startedAt: DateTime(2024),
      );
      expect(InterviewPracticeEngine.summarize(session), same(session));
    });
  });

  group('InterviewPracticeEngine.recommendNext', () {
    test('puts the weakest area first', () {
      final last = InterviewPracticeSession(
        id: 's1',
        userId: 'u',
        startedAt: DateTime(2024),
        recommendedNextArea: 'B',
      );
      final next = InterviewPracticeEngine.recommendNext(
        focusAreas: const ['A', 'B', 'C'],
        lastSession: last,
      );
      expect(next.first.requirement, 'B');
      expect(next.length, 3);
    });
  });
}

InterviewPracticeTurn _turn({
  required String focusArea,
  required int composite,
}) =>
    InterviewPracticeTurn(
      id: '$focusArea-$composite',
      question: 'Q',
      answer: 'A',
      focusArea: focusArea,
      relevanceScore: composite,
      specificityScore: composite,
      structureScore: composite,
      profileConsistencyScore: composite,
      compositeScore: composite,
      verdict: PracticeVerdict.good,
      feedbackStrengths: const [],
      feedbackImprove: const [],
      coachingSketch: '',
      unverifiedClaims: const [],
      createdAt: DateTime(2024),
    );
