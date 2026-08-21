import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/career_target.dart';
import '../../../domain/repositories/career_target_repository.dart';
import 'target_state.dart';

/// Manages the user's Career Targets: listing, creating, updating and deleting.
class TargetCubit extends Cubit<TargetState> {
  TargetCubit(this._repository) : super(const TargetState());

  final CareerTargetRepository _repository;

  Future<void> loadTargets() async {
    emit(state.copyWith(status: TargetStatus.loading, clearMessage: true));
    try {
      final targets = await _repository.loadAll();
      targets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      emit(
        state.copyWith(
          targets: targets,
          status: targets.isEmpty ? TargetStatus.empty : TargetStatus.loaded,
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          status: TargetStatus.failure,
          message: 'Could not load your targets. Please try again.',
        ),
      );
    }
  }

  Future<void> createTarget(CareerTarget target) async {
    try {
      final saved = await _repository.create(target);
      final targets = [saved, ...state.targets];
      emit(
        state.copyWith(
          targets: targets,
          status: TargetStatus.loaded,
          message: 'Target added',
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          status: TargetStatus.failure,
          message: 'Could not save the target. Please try again.',
        ),
      );
    }
  }

  Future<void> updateTarget(CareerTarget target) async {
    try {
      final saved = await _repository.update(target);
      final targets = [
        for (final existing in state.targets)
          if (existing.id == saved.id) saved else existing,
      ];
      emit(
        state.copyWith(
          targets: targets,
          status: TargetStatus.loaded,
          message: 'Target updated',
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          status: TargetStatus.failure,
          message: 'Could not update the target. Please try again.',
        ),
      );
    }
  }

  Future<void> deleteTarget(String id) async {
    final previous = state.targets;
    try {
      await _repository.delete(id);
      final targets = [
        for (final existing in state.targets)
          if (existing.id != id) existing,
      ];
      emit(
        state.copyWith(
          targets: targets,
          status: targets.isEmpty ? TargetStatus.empty : TargetStatus.loaded,
          message: 'Target deleted',
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          targets: previous,
          status: TargetStatus.failure,
          message: 'Could not delete the target. Please try again.',
        ),
      );
    }
  }
}
