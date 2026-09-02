import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/domain/entities/intake_question.dart';
import 'package:nexora/l10n/app_localizations.dart';
import 'package:nexora/presentation/career_dna/edit_widgets.dart';

void main() {
  testWidgets('showStructListSheet keeps typed link in result', (tester) async {
    final completer = Completer<List<Map<String, String>>?>();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  final result = await showStructListSheet(
                    context,
                    title: 'Projects',
                    schema: [
                      ListField(
                        name: 'name',
                        inputType: IntakeInputType.shortText,
                        label: (_) => 'Name',
                      ),
                      ListField(
                        name: 'links',
                        inputType: IntakeInputType.links,
                        label: (_) => 'Links',
                      ),
                    ],
                    items: [
                      {'name': 'ShipLink', 'links': '[]'},
                    ],
                  );
                  completer.complete(result);
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // LinksEditor is shown inline for the 'links' field.
    expect(find.byType(LinksEditor), findsOneWidget);

    await tester.tap(find.text('Add link'));
    await tester.pumpAndSettle();

    final urlFields = find.descendant(
      of: find.byType(LinksEditor),
      matching: find.byType(TextField),
    );
    await tester.enterText(urlFields.first, 'https://github.com/me/app');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    final result = await completer.future;
    expect(result, isNotNull);
    final links = result!.firstWhere((m) => m['name'] == 'ShipLink')['links'];
    expect(links, contains('https://github.com/me/app'));
  });
}
