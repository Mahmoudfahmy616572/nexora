import 'package:equatable/equatable.dart';

import '../../../../../domain/entities/career_target.dart';
import '../../../../../domain/entities/job_analysis.dart';

enum AnalyzeStatus {
  initial,
  loading,
  loaded,
  empty,
  success,
  failure,
}

/// State for the Analyze screen: target picker, analysis history, and the
/// current analysis result. The cubit owns NO scoring logic — all scoring lives
/// in the deterministic [OpportunityMatchEngine] invoked by the repository.
class AnalyzeState extends Equatable {
  const AnalyzeState({
    this.status = AnalyzeStatus.initial,
    this.analyses = const [],
    this.targets = const [],
    this.selectedTargetId,
    this.result,
    this.message,
  });

  final AnalyzeStatus status;
  final List<JobAnalysis> analyses;
  final List<CareerTarget> targets;
  final String? selectedTargetId;
  final JobAnalysis? result;
  final String? message;

  AnalyzeState copyWith({
    AnalyzeStatus? status,
    List<JobAnalysis>? analyses,
    List<CareerTarget>? targets,
    String? selectedTargetId,
    bool clearSelectedTarget = false,
    JobAnalysis? result,
    bool clearResult = false,
    String? message,
    bool clearMessage = false,
  }) =>
      AnalyzeState(
        status: status ?? this.status,
        analyses: analyses ?? this.analyses,
        targets: targets ?? this.targets,
        selectedTargetId:
            clearSelectedTarget ? null : (selectedTargetId ?? this.selectedTargetId),
        result: clearResult ? null : (result ?? this.result),
        message: clearMessage ? null : (message ?? this.message),
      );

  @override
  List<Object?> get props =>
      [status, analyses, targets, selectedTargetId, result, message];
}
