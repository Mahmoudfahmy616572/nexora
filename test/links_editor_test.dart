import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/presentation/career_dna/edit_widgets.dart';

void main() {
  testWidgets('LinksEditor emits JSON containing typed URL', (tester) async {
    String? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LinksEditor(
            initial: '',
            hint: 'Links',
            onChanged: (v) => captured = v,
          ),
        ),
      ),
    );

    // Add a link row.
    await tester.tap(find.text('Add link'));
    await tester.pumpAndSettle();

    final urlFields = find
        .descendant(of: find.byType(LinksEditor), matching: find.byType(TextField));
    expect(urlFields.evaluate().length, 2); // url + label

    await tester.enterText(urlFields.first, 'https://github.com/me/app');
    await tester.pump();

    expect(captured, isNotNull);
    expect(captured, contains('https://github.com/me/app'));
  });
}
