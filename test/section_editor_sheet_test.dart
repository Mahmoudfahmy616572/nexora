import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/features/main/presentation/dna_screen.dart';
import 'package:nexora/presentation/career_dna/edit_widgets.dart';

void main() {
  testWidgets('real SectionEditorSheet stores the project link', (tester) async {
    final completer = Completer<List<List<String>>?>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final r = await showModalBottomSheet<List<List<String>>>(
                  context: context,
                  builder: (_) => const SectionEditorSheet(
                    title: 'Projects',
                    subtitle: 'Add your projects',
                    fields: [
                      FieldSpec(label: 'Name', hint: 'n'),
                      FieldSpec(label: 'Description', hint: 'd', lines: 3),
                      FieldSpec(label: 'Tech', hint: 't'),
                      FieldSpec(label: 'Links', hint: 'l', isLinks: true),
                    ],
                    initial: [],
                  ),
                );
                completer.complete(r);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final textFields = find.descendant(
      of: find.byType(SectionEditorSheet),
      matching: find.byType(TextField),
    );

    await tester.enterText(textFields.at(0), 'ShipLink');
    await tester.enterText(textFields.at(1), 'A shipping app');
    await tester.enterText(textFields.at(2), 'Flutter, Dart');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Add link'));
    await tester.tap(find.text('Add link'));
    await tester.pumpAndSettle();

    final urlFields = find.descendant(
      of: find.byType(LinksEditor),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(urlFields.first);
    await tester.enterText(urlFields.first, 'https://github.com/me/app');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add'));
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    final result = await completer.future;
    expect(result, isNotNull, reason: 'sheet should return entries');
    expect(result!, isNotEmpty, reason: 'one entry should be present');
    expect(result.first.length, 4, reason: 'projects have 4 columns');
    expect(result.first[3], contains('https://github.com/me/app'),
        reason: 'the typed link URL must be in the links column');
  });

  testWidgets('edit existing project then add link via Update', (tester) async {
    final completer = Completer<List<List<String>>?>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final r = await showModalBottomSheet<List<List<String>>>(
                  context: context,
                  builder: (_) => const SectionEditorSheet(
                    title: 'Projects',
                    subtitle: 'Add your projects',
                    fields: [
                      FieldSpec(label: 'Name', hint: 'n'),
                      FieldSpec(label: 'Description', hint: 'd', lines: 3),
                      FieldSpec(label: 'Tech', hint: 't'),
                      FieldSpec(label: 'Links', hint: 'l', isLinks: true),
                    ],
                    initial: [
                      ['ShipLink', 'A shipping app', 'Flutter, Dart'],
                    ],
                  ),
                );
                completer.complete(r);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Edit the existing entry (the card's edit button).
    await tester.ensureVisible(find.byIcon(Icons.edit_outlined));
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Add link'));
    await tester.tap(find.text('Add link'));
    await tester.pumpAndSettle();

    final urlFields = find.descendant(
      of: find.byType(LinksEditor),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(urlFields.first);
    await tester.enterText(urlFields.first, 'https://github.com/me/app');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Update'));
    await tester.tap(find.widgetWithText(FilledButton, 'Update'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    final result = await completer.future;
    expect(result, isNotNull);
    expect(result!, isNotEmpty);
    expect(result.first.length, 4, reason: 'links column must be present after edit');
    expect(result.first[3], contains('https://github.com/me/app'),
        reason: 'the typed link URL must be stored on the edited project');
  });
}
