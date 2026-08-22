import '../entities/career_dna.dart';
import '../entities/interview_prep.dart';
import '../entities/profile_data.dart';
import '../profile_generator.dart';

/// One step of the contextual interview exchange.
class InterviewTurn {
  const InterviewTurn({required this.question, required this.answer});

  final String question;
  final String answer;
}

/// Result of a single interview call to the AI.
///
/// Either [done] is false and [question] holds the next prompt, or [done] is true
/// and [profile] holds the extracted [ProfileData].
class InterviewResult {
  const InterviewResult({required this.done, this.question, this.profile});

  final bool done;
  final String? question;
  final ProfileData? profile;
}

/// Stores and evolves the user's Career DNA — the central entity of the product.
///
/// Supabase is the source of truth when reachable; a SharedPreferences fallback
/// keeps the flow working signed out or offline. A `null` result from [load]
/// means no Career DNA has been created yet.
abstract interface class CareerDnaRepository {
  /// Returns the current Career DNA, or `null` when nothing has been saved.
  Future<CareerDna?> load();

  /// Persists the DNA. If a prior version exists, bumps [CareerDna.version] and
  /// records a snapshot in the version history. Returns the saved DNA.
  Future<CareerDna> save(CareerDna dna);

  /// The recorded version history, newest first (empty when none).
  Future<List<CareerDna>> versions();

  /// Drafts a structured [ProfileData] (plus skills) from the raw interview
  /// facts via the hosted AI function. Throws on hard failure so the caller can
  /// fall back to local generation.
  Future<GeneratedProfile> draftProfile({
    required String target,
    required String education,
    required String experience,
    required String skills,
  });

  /// Runs one contextual interview turn. [context] is the current Career DNA
  /// fields, [history] the prior question/answer pairs, [language] the locale
  /// code, and [finish] asks the model to finalize instead of asking another
  /// question. Throws on hard failure so the caller can fall back.
  Future<InterviewResult> interview({
    required Map<String, dynamic> context,
    required List<Map<String, dynamic>> history,
    required String language,
    required bool finish,
  });

  /// Generates an interview readiness plan for [targetRole] (optional [company])
  /// grounded strictly in the candidate [context] (their real Career DNA / CV)
  /// and the given [focusAreas] (deterministic gap labels). Throws on hard
  /// failure so the caller can fall back to a deterministic plan.
  Future<InterviewPrepPlan> generateInterviewPlan({
    required Map<String, dynamic> context,
    required List<String> focusAreas,
    required String language,
    String? targetRole,
    String? company,
  });
}
