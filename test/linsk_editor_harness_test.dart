import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/presentation/career_dna/edit_widgets.dart';

class _Harness extends StatefulWidget {
  const _Harness();

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  String _linksJson = '';

  void _save() {
    // mirrors dna_screen _saveEntry link branch
    final json = _linksJson.trim();
    final stored = json == '[]' || json.isEmpty ? '' : json;
    _saved = stored;
  }

  String _saved = '';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            LinksEditor(
              initial: _linksJson,
              hint: 'Links',
              onChanged: (v) => setState(() => _linksJson = v),
            ),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('parent setState keeps link value through save', (tester) async {
    await tester.pumpWidget(const _Harness());

    await tester.tap(find.text('Add link'));
    await tester.pumpAndSettle();

    final urlFields = find.descendant(
      of: find.byType(LinksEditor),
      matching: find.byType(TextField),
    );
    await tester.enterText(urlFields.first, 'https://github.com/me/app');
    await tester.pumpAndSettle();

    // At this point the parent rebuild happened via onChanged's setState.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Inspect the harness state.
    final state = tester.state<_HarnessState>(find.byType(_Harness));
    expect(state._saved, contains('https://github.com/me/app'));
  });
}
