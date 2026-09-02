import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/data/data_sources/career_local_data_source.dart';
import 'package:nexora/data/data_sources/career_remote_data_source.dart';
import 'package:nexora/data/repositories/career_repository_impl.dart';
import 'package:nexora/domain/entities/job_application.dart';

/// Remote that returns canned rows or fails, to exercise the fallback path.
class _FakeRemote extends CareerRemoteDataSource {
  List<Map<String, dynamic>>? fetchAllResult;
  bool fetchAllThrows = false;
  String? replaceAllTable;
  List<Map<String, dynamic>>? replaceAllRows;
  bool replaceAllThrows = false;

  @override
  Future<List<Map<String, dynamic>>> fetchAll(String table) async {
    if (fetchAllThrows) throw StateError('remote unavailable');
    return fetchAllResult ?? const [];
  }

  @override
  Future<void> replaceAll(String table, List<Map<String, dynamic>> rows) async {
    if (replaceAllThrows) throw StateError('remote unavailable');
    replaceAllTable = table;
    replaceAllRows = rows;
  }
}

/// Local store that captures reads/writes instead of touching SharedPreferences.
class _FakeLocal extends CareerLocalDataSource {
  _FakeLocal() : super(null);
  List<String>? readListResult;
  String? writeListKey;
  List<String>? writeListValues;

  @override
  Future<List<String>?> readList(String key) async => readListResult;

  @override
  Future<void> writeList(String key, List<String> values) async {
    writeListKey = key;
    writeListValues = values;
  }
}

JobApplication _app(String id) => JobApplication(
      id: id,
      company: 'Acme',
      role: 'Dev',
      status: 'Applied',
      date: '2026-08-22',
      match: 80,
      ats: 84,
    );

Map<String, dynamic> _row(String id) => {
      'id': id,
      'company': 'Acme',
      'role': 'Dev',
      'status': 'Applied',
      'date': '2026-08-22',
      'match': 80,
      'ats': 84,
    };

void main() {
  group('JobApplicationRepositoryImpl', () {
    test('load prefers remote rows when available', () async {
      final remote = _FakeRemote()..fetchAllResult = [_row('a1')];
      final local = _FakeLocal();
      final repo = JobApplicationRepositoryImpl(remote, local);

      final result = await repo.load();

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result.first.id, 'a1');
      expect(result.first.company, 'Acme');
      // Local fallback was not consulted for data.
      expect(local.readListResult, isNull);
    });

    test('load falls back to local when remote throws', () async {
      final remote = _FakeRemote()..fetchAllThrows = true;
      final local = _FakeLocal()
        ..readListResult = [jsonEncode(_row('a2'))];
      final repo = JobApplicationRepositoryImpl(remote, local);

      final result = await repo.load();

      expect(result, isNotNull);
      expect(result!.first.id, 'a2');
      expect(result.first.status, 'Applied');
    });

    test('load returns null when nothing is stored anywhere', () async {
      final remote = _FakeRemote()..fetchAllThrows = true;
      final local = _FakeLocal()..readListResult = null;
      final repo = JobApplicationRepositoryImpl(remote, local);

      final result = await repo.load();

      expect(result, isNull);
    });

    test('saveAll writes to the job_applications table via remote', () async {
      final remote = _FakeRemote();
      final local = _FakeLocal();
      final repo = JobApplicationRepositoryImpl(remote, local);

      await repo.saveAll([_app('a1'), _app('a2')]);

      expect(remote.replaceAllTable, 'job_applications');
      expect(remote.replaceAllRows, hasLength(2));
      expect(remote.replaceAllRows!.first['id'], 'a1');
      // Local mirror is always written for resilience.
      expect(local.writeListValues, hasLength(2));
    });

    test('saveAll falls back to local when remote throws', () async {
      final remote = _FakeRemote()..replaceAllThrows = true;
      final local = _FakeLocal();
      final repo = JobApplicationRepositoryImpl(remote, local);

      await repo.saveAll([_app('a1')]);

      expect(local.writeListKey, 'tracker.apps');
      expect(local.writeListValues, hasLength(1));
      expect(local.writeListValues!.first, contains('"id":"a1"'));
    });
  });
}
