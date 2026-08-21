import 'package:equatable/equatable.dart';

import '../../../domain/entities/career_target.dart';

enum TargetStatus {
  initial,
  loading,
  loaded,
  empty,
  success,
  failure,
}

class TargetState extends Equatable {
  const TargetState({
    this.status = TargetStatus.initial,
    this.targets = const [],
    this.message,
  });

  final TargetStatus status;
  final List<CareerTarget> targets;
  final String? message;

  TargetState copyWith({
    TargetStatus? status,
    List<CareerTarget>? targets,
    String? message,
    bool clearMessage = false,
  }) =>
      TargetState(
        status: status ?? this.status,
        targets: targets ?? this.targets,
        message: clearMessage ? null : (message ?? this.message),
      );

  @override
  List<Object?> get props => [status, targets, message];
}
