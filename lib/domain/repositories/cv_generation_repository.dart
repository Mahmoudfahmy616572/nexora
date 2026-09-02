import '../entities/career_dna.dart';
import '../entities/career_target.dart';
import '../entities/cv_content.dart';
import '../entities/job_analysis.dart';
import '../entities/user_identity.dart';

/// Calls the hosted AI `cv_generate` edge function and returns structured
/// [CvContent]. Any failure (unconfigured, signed out, offline, malformed)
/// must throw — the caller is responsible for falling back to the deterministic
/// [CvFactualBuilder].
abstract class CvGenerationRepository {
  Future<CvContent> generate({
    required CareerDna dna,
    required CareerTarget target,
    JobAnalysis? analysis,
    required String templateId,
    required String language,
    UserIdentity? identity,
  });
}
