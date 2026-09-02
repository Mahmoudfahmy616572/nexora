import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/core/theme/app_colors.dart';
import 'package:nexora/domain/entities/user_identity.dart';
import 'package:nexora/features/main/presentation/widgets/section_row.dart';

void main() {
  group('SectionRow subtitle', () {
    testWidgets('does not show subtitle when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionRow(
              icon: Icons.person_rounded,
              label: 'Personal Profile',
              pct: 50,
            ),
          ),
        ),
      );
      expect(find.text('Identity & contact details'), findsNothing);
      expect(find.text('Personal Profile'), findsOneWidget);
    });

    testWidgets('shows subtitle below label when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionRow(
              icon: Icons.person_rounded,
              label: 'Personal Profile',
              pct: 50,
              subtitle: 'Identity & contact details',
            ),
          ),
        ),
      );
      expect(find.text('Personal Profile'), findsOneWidget);
      expect(find.text('Identity & contact details'), findsOneWidget);
    });
  });

  group('SectionRow statusText', () {
    testWidgets('shows percentage when statusText is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionRow(
              icon: Icons.person_rounded,
              label: 'Personal Profile',
              pct: 50,
            ),
          ),
        ),
      );
      expect(find.text('50%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows statusText instead of percentage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionRow(
              icon: Icons.person_rounded,
              label: 'Personal Profile',
              pct: 50,
              statusText: '\u2713 Complete',
            ),
          ),
        ),
      );
      expect(find.text('\u2713 Complete'), findsOneWidget);
      expect(find.text('50%'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('statusText with checkmark uses teal color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionRow(
              icon: Icons.person_rounded,
              label: 'Personal Profile',
              pct: 100,
              statusText: '\u2713 Complete',
            ),
          ),
        ),
      );
      final textWidget = tester.widget<Text>(find.text('\u2713 Complete'));
      expect(textWidget.style?.color, AppColors.teal);
    });

    testWidgets('statusText with warning uses amber color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionRow(
              icon: Icons.person_rounded,
              label: 'Personal Profile',
              pct: 38,
              statusText: '\u26A0 5 items missing',
            ),
          ),
        ),
      );
      final textWidget = tester.widget<Text>(find.text('\u26A0 5 items missing'));
      expect(textWidget.style?.color, AppColors.amber);
    });
  });

  group('SectionRow combined', () {
    testWidgets('shows subtitle and statusText together', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionRow(
              icon: Icons.person_rounded,
              label: 'Personal Profile',
              pct: 50,
              subtitle: 'Identity & contact details',
              statusText: '\u26A0 5 items missing',
            ),
          ),
        ),
      );
      expect(find.text('Personal Profile'), findsOneWidget);
      expect(find.text('Identity & contact details'), findsOneWidget);
      expect(find.text('\u26A0 5 items missing'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('50%'), findsNothing);
    });
  });

  group('UserIdentity completeness', () {
    test('all fields empty results in isEmpty', () {
      const identity = UserIdentity();
      expect(identity.isEmpty, isTrue);
    });

    test('some fields filled results in !isEmpty', () {
      const identity = UserIdentity(fullName: 'Jane Doe', email: 'jane@example.com');
      expect(identity.isEmpty, isFalse);
    });

    test('identity completeness calculation', () {
      const identity = UserIdentity(
        fullName: 'Jane Doe',
        professionalTitle: 'Flutter Engineer',
        email: 'jane@example.com',
      );
      final fields = [
        identity.fullName,
        identity.professionalTitle,
        identity.email,
        identity.phone,
        identity.location,
        identity.linkedinUrl,
        identity.githubUrl,
        identity.portfolioUrl,
      ];
      final filledCount = fields.where((f) => f.isNotEmpty).length;
      final pct = (filledCount * 100 / fields.length).toDouble();
      expect(filledCount, 3);
      expect(pct, closeTo(37.5, 0.1));
    });

    test('all fields filled = 100%', () {
      const identity = UserIdentity(
        fullName: 'Jane Doe',
        professionalTitle: 'Flutter Engineer',
        email: 'jane@example.com',
        phone: '+971501234567',
        location: 'Dubai, UAE',
        linkedinUrl: 'https://linkedin.com/in/jane',
        githubUrl: 'https://github.com/jane',
        portfolioUrl: 'https://jane.dev',
      );
      final fields = [
        identity.fullName,
        identity.professionalTitle,
        identity.email,
        identity.phone,
        identity.location,
        identity.linkedinUrl,
        identity.githubUrl,
        identity.portfolioUrl,
      ];
      final filledCount = fields.where((f) => f.isNotEmpty).length;
      final allFilled = filledCount == fields.length;
      final pct = (filledCount * 100 / fields.length).toDouble();
      expect(allFilled, isTrue);
      expect(pct, 100.0);
    });

    test('no fields filled = 0%', () {
      const identity = UserIdentity();
      final fields = [
        identity.fullName,
        identity.professionalTitle,
        identity.email,
        identity.phone,
        identity.location,
        identity.linkedinUrl,
        identity.githubUrl,
        identity.portfolioUrl,
      ];
      final filledCount = fields.where((f) => f.isNotEmpty).length;
      final pct = fields.isEmpty ? 0.0 : (filledCount * 100 / fields.length).toDouble();
      expect(pct, 0.0);
    });
  });
}
