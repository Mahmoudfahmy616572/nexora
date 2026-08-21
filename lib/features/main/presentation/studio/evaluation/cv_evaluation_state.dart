import 'package:equatable/equatable.dart';

import '../../../../../domain/entities/cv_content.dart';
import '../../../../../domain/entities/cv_evaluation.dart';

enum CvEvaluationStatus {
  initial,
  loading,
  ready,
  applyingSuggestion,
  failure,
}

class CvEvaluationState extends Equatable {
  const CvEvaluationState({
    this.status = CvEvaluationStatus.initial,
    this.evaluation,
    this.suggestions = const [],
    this.content,
    this.message,
    this.deterministicOnly = false,
  });

  final CvEvaluationStatus status;
  final CvEvaluation? evaluation;
  final List<CvSuggestion> suggestions;
  final CvContent? content;
  final String? message;
  final bool deterministicOnly;

  CvEvaluationState copyWith({
    CvEvaluationStatus? status,
    CvEvaluation? evaluation,
    bool clearEvaluation = false,
    List<CvSuggestion>? suggestions,
    CvContent? content,
    bool clearContent = false,
    String? message,
    bool clearMessage = false,
    bool? deterministicOnly,
  }) =>
      CvEvaluationState(
        status: status ?? this.status,
        evaluation: clearEvaluation ? null : (evaluation ?? this.evaluation),
        suggestions: suggestions ?? this.suggestions,
        content: clearContent ? null : (content ?? this.content),
        message: clearMessage ? null : (message ?? this.message),
        deterministicOnly: deterministicOnly ?? this.deterministicOnly,
      );

  @override
  List<Object?> get props =>
      [status, evaluation, suggestions, content, message, deterministicOnly];
}
