import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/data/data_sources/career_local_data_source.dart';
import 'package:nexora/data/data_sources/career_remote_data_source.dart';
import 'package:nexora/data/repositories/career_dna_repository_impl.dart';

/// Remote that simulates the AI edge function failing (timeout, 5xx, bad JSON).
class _FailingRemote extends CareerRemoteDataSource {
  @override
  Future<Map<String, dynamic>> runAiProfileDraft(Map<String, dynamic> input) async {
    throw Exception('simulated AI failure');
  }
}

void main() {
  test('draftProfile rethrows when the AI call fails', () async {
    final repo = CareerDnaRepositoryImpl(
      remote: _FailingRemote(),
      local: CareerLocalDataSource(null),
    );
    expect(
      () => repo.draftProfile(
        target: 'Flutter dev',
        education: 'B.Sc. CS',
        experience: 'built an app',
        skills: 'Dart',
      ),
      throwsA(isA<Exception>()),
    );
  });
}
