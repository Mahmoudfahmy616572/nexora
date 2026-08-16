import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/career_dna.dart';
import '../../../domain/repositories/career_dna_repository.dart';

enum DnaStatus { initial, loading, ready, saving, saved, error }

class CareerDnaState {
  const CareerDnaState({
    this.status = DnaStatus.initial,
    this.dna,
    this.error,
  });

  final DnaStatus status;
  final CareerDna? dna;
  final String? error;

  CareerDnaState copyWith({
    DnaStatus? status,
    CareerDna? dna,
    String? error,
    bool clearError = false,
  }) =>
      CareerDnaState(
        status: status ?? this.status,
        dna: dna ?? this.dna,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Holds the in-progress Career DNA as it is built across the adaptive intake,
/// the AI interview, and the review screen, and persists it on save.
///
/// Provided once at the app root so every screen in the creation flow shares
/// the same draft.
class CareerDnaCubit extends Cubit<CareerDnaState> {
  CareerDnaCubit({required this.repository}) : super(const CareerDnaState());

  final CareerDnaRepository repository;

  /// Loads any existing DNA (e.g. a returning user who abandoned the flow).
  Future<void> load() async {
    emit(state.copyWith(status: DnaStatus.loading, clearError: true));
    try {
      final dna = await repository.load();
      emit(state.copyWith(status: DnaStatus.ready, dna: dna));
    } on Object {
      emit(state.copyWith(status: DnaStatus.ready, dna: null));
    }
  }

  /// Replaces the current draft (used by the intake and interview steps).
  void updateDraft(CareerDna draft) =>
      emit(state.copyWith(status: DnaStatus.ready, dna: draft));

  /// Persists the draft, bumping its version and recording a snapshot.
  Future<CareerDna> save() async {
    final current = state.dna;
    if (current == null) throw StateError('No draft to save');
    emit(state.copyWith(status: DnaStatus.saving, clearError: true));
    try {
      final saved = await repository.save(current);
      emit(state.copyWith(status: DnaStatus.saved, dna: saved));
      return saved;
    } on Object catch (e) {
      emit(state.copyWith(status: DnaStatus.ready, error: e.toString()));
      rethrow;
    }
  }
}
