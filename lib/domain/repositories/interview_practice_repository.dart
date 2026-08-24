import '../entities/interview_practice_session.dart';

/// Persists Interview Practice Coach sessions (Phase 5).
///
/// Sessions are append-only / additive: a new session is created, turns are
/// accumulated, and on completion the summary scores are written once. Raw AI
/// responses are never persisted — only the deterministic scoring and, if
/// available, the model-authored coaching sketch.
abstract interface class InterviewPracticeRepository {
  /// Upserts a session (insert or replace by [InterviewPracticeSession.id]).
  Future<void> save(InterviewPracticeSession session);

  /// Most recent sessions, newest first (capped by [limit]).
  Future<List<InterviewPracticeSession>> loadRecent(int limit);

  /// A single session by id, or `null`.
  Future<InterviewPracticeSession?> loadById(String id);

  /// Removes a session by id.
  Future<void> delete(String id);
}
