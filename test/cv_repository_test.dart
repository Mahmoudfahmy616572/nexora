import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nexora/data/data_sources/career_local_data_source.dart';
import 'package:nexora/data/data_sources/career_remote_data_source.dart';
import 'package:nexora/data/repositories/career_repository_impl.dart';
import 'package:nexora/domain/entities/cv_content.dart';
import 'package:nexora/domain/entities/cv_document.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  CvDocumentRepositoryImpl repo(SharedPreferences prefs) =>
      CvDocumentRepositoryImpl(CareerRemoteDataSource(), CareerLocalDataSource(prefs));

  CvDocument doc(String id, String title) => CvDocument(
        id: id,
        userId: 'u',
        targetId: 't',
        templateId: 'nexoraMinimal',
        title: title,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

  CvVersion ver(String id, String documentId) => CvVersion(
        id: id,
        documentId: documentId,
        userId: 'u',
        version: 0,
        content: const CvContent(summary: 'a'),
        templateId: 'nexoraMinimal',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

  test('createDocument then loadDocuments returns the document', () async {
    final prefs = await SharedPreferences.getInstance();
    final r = repo(prefs);
    await r.createDocument(doc('d1', 'CV'));
    final docs = await r.loadDocuments();
    expect(docs.any((d) => d.id == 'd1'), isTrue);
  });

  test('createVersion increments deterministically', () async {
    final prefs = await SharedPreferences.getInstance();
    final r = repo(prefs);
    await r.createDocument(doc('d1', 'CV'));
    final v1 = await r.createVersion(ver('v1', 'd1'));
    final v2 = await r.createVersion(ver('v2', 'd1'));
    expect(v1.version, 1);
    expect(v2.version, 2);
  });

  test('loadVersions filters by document and latest is highest', () async {
    final prefs = await SharedPreferences.getInstance();
    final r = repo(prefs);
    await r.createDocument(doc('d1', 'A'));
    await r.createDocument(doc('d2', 'B'));
    await r.createVersion(ver('a', 'd1'));
    await r.createVersion(ver('b', 'd2'));
    expect((await r.loadVersions('d1')).length, 1);
    expect((await r.loadLatestVersion('d1'))?.id, 'a');
  });

  test('deleteDocument removes document and its versions', () async {
    final prefs = await SharedPreferences.getInstance();
    final r = repo(prefs);
    await r.createDocument(doc('d1', 'A'));
    await r.createVersion(ver('a', 'd1'));
    await r.deleteDocument('d1');
    expect(await r.loadDocument('d1'), isNull);
    expect(await r.loadVersions('d1'), isEmpty);
  });
}
