import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/domain/entities/career_target.dart';

void main() {
  group('CareerTarget', () {
    test('newId produces a valid v4 UUID', () {
      final id = CareerTarget.newId();
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
            .hasMatch(id),
        isTrue,
        reason: 'expected RFC-4122 v4 UUID, got $id',
      );
    });

    test('toJson/fromJson round-trips all fields', () {
      final target = CareerTarget(
        id: CareerTarget.newId(),
        userId: 'user-1',
        type: TargetType.graduateProgram,
        role: 'M.Sc. Robotics',
        industry: 'AI',
        countryRegion: 'Germany',
        seniority: 'Entry',
        language: 'English',
        jobDescription: 'Requirements...',
        company: 'TU Munich',
        url: 'https://example.com',
        createdAt: DateTime.utc(2026, 1, 2, 3, 4),
        updatedAt: DateTime.utc(2026, 1, 2, 3, 5),
      );
      final json = target.toJson();
      final restored = CareerTarget.fromJson(json);
      expect(restored.id, target.id);
      expect(restored.userId, target.userId);
      expect(restored.type, TargetType.graduateProgram);
      expect(restored.role, target.role);
      expect(restored.industry, target.industry);
      expect(restored.countryRegion, target.countryRegion);
      expect(restored.seniority, target.seniority);
      expect(restored.language, target.language);
      expect(restored.jobDescription, target.jobDescription);
      expect(restored.company, target.company);
      expect(restored.url, target.url);
      expect(restored.createdAt, target.createdAt);
      expect(restored.updatedAt, target.updatedAt);
    });

    test('nullable fields serialize to absent keys and restore as null', () {
      final target = CareerTarget(
        id: 'x',
        userId: 'u',
        type: TargetType.custom,
        role: 'Custom',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      final json = target.toJson();
      expect(json.containsKey('industry'), isFalse);
      expect(json.containsKey('company'), isFalse);
      final restored = CareerTarget.fromJson(json);
      expect(restored.industry, isNull);
      expect(restored.company, isNull);
      expect(restored.type, TargetType.custom);
    });

    test('copyWith overrides only provided fields', () {
      final target = CareerTarget(
        id: 'x',
        userId: 'u',
        type: TargetType.job,
        role: 'Original',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      final updated = target.copyWith(role: 'Changed');
      expect(updated.role, 'Changed');
      expect(updated.type, TargetType.job);
      expect(updated.id, target.id);
    });
  });
}
