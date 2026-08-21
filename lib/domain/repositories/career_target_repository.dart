import '../entities/career_target.dart';

/// Persists and retrieves the user's Career Targets.
abstract class CareerTargetRepository {
  /// All targets owned by the current user (empty list when none).
  Future<List<CareerTarget>> loadAll();

  /// A single target by [id], or `null` when it does not exist.
  Future<CareerTarget?> loadById(String id);

  /// Inserts a new target and returns it (with server-generated id preserved).
  Future<CareerTarget> create(CareerTarget target);

  /// Replaces an existing target and returns it.
  Future<CareerTarget> update(CareerTarget target);

  /// Removes the target with [id].
  Future<void> delete(String id);
}
