import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nexora/data/data_sources/career_local_data_source.dart';
import 'package:nexora/data/data_sources/career_remote_data_source.dart';
import 'package:nexora/data/repositories/career_repository_impl.dart';
import 'package:nexora/domain/entities/career_target.dart';
import 'package:nexora/presentation/target/cubit/target_cubit.dart';
import 'package:nexora/presentation/target/cubit/target_state.dart';

CareerTargetRepositoryImpl _repo(SharedPreferences prefs) =>
    CareerTargetRepositoryImpl(CareerRemoteDataSource(), CareerLocalDataSource(prefs));

CareerTarget _sample({String id = 't1', String role = 'Flutter Dev'}) => CareerTarget(
      id: id,
      userId: 'u',
      type: TargetType.job,
      role: role,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('CareerTargetRepository (local fallback)', () {
    testWidgets('create, load, update and delete persist locally', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final repo = _repo(prefs);

      expect(await repo.loadAll(), isEmpty);

      final created = await repo.create(_sample());
      final all = await repo.loadAll();
      expect(all, hasLength(1));
      expect(all.first.role, 'Flutter Dev');

      final updated = created.copyWith(role: 'Senior Flutter Dev');
      await repo.update(updated);
      final afterUpdate = await repo.loadAll();
      expect(afterUpdate, hasLength(1));
      expect(afterUpdate.first.role, 'Senior Flutter Dev');

      await repo.delete(created.id);
      expect(await repo.loadAll(), isEmpty);
    });

    testWidgets('loadById returns the matching target', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final repo = _repo(prefs);
      await repo.create(_sample(id: 'a'));
      await repo.create(_sample(id: 'b', role: 'Designer'));
      final found = await repo.loadById('b');
      expect(found?.role, 'Designer');
      expect(await repo.loadById('missing'), isNull);
    });
  });

  group('TargetCubit', () {
    testWidgets('create adds a target and exposes it in state', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = TargetCubit(_repo(prefs));
      await cubit.createTarget(_sample(role: 'Backend Engineer'));
      expect(cubit.state.status, TargetStatus.loaded);
      expect(cubit.state.targets, hasLength(1));
      expect(cubit.state.targets.first.role, 'Backend Engineer');
      await cubit.close();
    });

    testWidgets('delete removes the target and flips to empty', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = TargetCubit(_repo(prefs));
      final target = _sample();
      await cubit.createTarget(target);
      await cubit.deleteTarget(target.id);
      expect(cubit.state.targets, isEmpty);
      expect(cubit.state.status, TargetStatus.empty);
      await cubit.close();
    });
  });
}
