import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/domain/entities/cv_content.dart';
import 'package:nexora/domain/entities/cv_document.dart';

void main() {
  test('CvDocument toJson/fromJson round-trips', () {
    final d = CvDocument(
      id: 'd1',
      userId: 'u1',
      targetId: 't1',
      templateId: 'nexoraModern',
      title: 'My CV',
      analysisId: 'a1',
      createdAt: DateTime.utc(2026, 1, 2),
      updatedAt: DateTime.utc(2026, 1, 3),
    );
    final back = CvDocument.fromJson(d.toJson());
    expect(back.id, 'd1');
    expect(back.targetId, 't1');
    expect(back.analysisId, 'a1');
    expect(back.templateId, 'nexoraModern');
  });

  test('CvVersion toJson/fromJson round-trips content', () {
    final v = CvVersion(
      id: 'v1',
      documentId: 'd1',
      userId: 'u1',
      version: 2,
      content: const CvContent(summary: 'hi'),
      templateId: 'nexoraMinimal',
      createdAt: DateTime.utc(2026, 1, 2),
      updatedAt: DateTime.utc(2026, 1, 3),
    );
    final back = CvVersion.fromJson(v.toJson());
    expect(back.version, 2);
    expect(back.content.summary, 'hi');
  });

  test('CvDocument copyWith', () {
    final d = CvDocument(
        id: 'd',
        userId: 'u',
        targetId: 't',
        templateId: 'a',
        title: 'T',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1));
    expect(d.copyWith(title: 'X').title, 'X');
  });
}
