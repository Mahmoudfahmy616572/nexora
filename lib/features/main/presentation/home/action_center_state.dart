import 'package:equatable/equatable.dart';

import '../../../../domain/action_center/action_center.dart';

enum ActionCenterStatus {
  initial,
  loading,
  ready,
  failure,
}

class ActionCenterCubitState extends Equatable {
  const ActionCenterCubitState({
    this.status = ActionCenterStatus.initial,
    this.decision,
    this.error,
  });

  final ActionCenterStatus status;
  final ActionCenterState? decision;
  final String? error;

  ActionCenterCubitState copyWith({
    ActionCenterStatus? status,
    ActionCenterState? decision,
    bool clearDecision = false,
    String? error,
    bool clearError = false,
  }) =>
      ActionCenterCubitState(
        status: status ?? this.status,
        decision: clearDecision ? null : (decision ?? this.decision),
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [status, decision, error];
}
