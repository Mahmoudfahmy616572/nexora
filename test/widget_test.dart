import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/app.dart';

void main() {
  setUpAll(() async {
    // Load the real Inter font so text metrics match production devices
    // (the default test font renders every glyph as a full em square).
    final data = await rootBundle.load('assets/fonts/Inter-Variable.ttf');
    final loader = FontLoader('Inter');
    loader.addFont(Future.value(data));
    await loader.load();
  });

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const NexoraApp());
  }

  testWidgets('Welcome screen renders on desktop', (tester) async {
    await pumpAt(tester, const Size(1440, 900));

    expect(find.text('NEXORA'), findsOneWidget);
    expect(find.text('CAREER INTELLIGENCE'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
    expect(find.textContaining('Elevated.'), findsOneWidget);
    expect(find.text('CAREER DNA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Welcome screen renders on mobile without overflow', (tester) async {
    await pumpAt(tester, const Size(390, 844));

    expect(find.text('NEXORA'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Welcome screen renders on narrow device', (tester) async {
    await pumpAt(tester, const Size(320, 700));

    expect(find.text('Get Started'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
