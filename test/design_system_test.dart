import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/core/theme/app_colors.dart';
import 'package:nexora/core/theme/app_motion.dart';

void main() {
  group('Design system', () {
    test('color tokens resolve to the new deep-ink identity', () {
      expect(AppColors.background, const Color(0xFF0B0C0E));
      expect(AppColors.brand, const Color(0xFF46E6B0));
      expect(AppColors.accent, const Color(0xFF6C8CFF));
      // No ambient gradient — mid equals the solid ink background.
      expect(AppColors.backgroundGradientMid, AppColors.background);
    });

    testWidgets('NxReveal shows child immediately under reduced motion', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: NxReveal(child: const Text('reveal-me')),
          ),
        ),
      );
      expect(find.text('reveal-me'), findsOneWidget);
    });

    testWidgets('NxMetric renders plain value under reduced motion', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: NxMetric(value: 42, builder: (v) => '${v.round()}%'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('42%'), findsOneWidget);
    });

    testWidgets('NxPress does not throw and renders child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NxPress(
            onTap: () {},
            child: const Text('press-me'),
          ),
        ),
      );
      expect(find.text('press-me'), findsOneWidget);
    });
  });
}
