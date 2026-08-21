import '../entities/cv_evaluation.dart';

/// Persistence for first-class CV improvement suggestions.
abstract class CvSuggestionRepository {
  Future<List<CvSuggestion>> loadByEvaluation(String evaluationId);

  Future<CvSuggestion> saveSuggestion(CvSuggestion suggestion);

  Future<CvSuggestion> updateSuggestion(CvSuggestion suggestion);

  Future<void> deleteForEvaluation(String evaluationId);
}
