import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/presentation/career_dna/edit_widgets.dart';

class _FieldSpec {
  const _FieldSpec({required this.label, this.isLinks = false});
  final String label;
  final bool isLinks;
}

class _Harness extends StatefulWidget {
  const _Harness();

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final _fields = const [
    _FieldSpec(label: 'Name'),
    _FieldSpec(label: 'Description'),
    _FieldSpec(label: 'Tech'),
    _FieldSpec(label: 'Links', isLinks: true),
  ];
  final _controllers = [TextEditingController(), TextEditingController(), TextEditingController()];
  String _linksJson = '';
  int? _editingIndex;
  List<List<String>> _entries = [];

  void _startEdit() {
    setState(() {
      _editingIndex = null;
      _linksJson = '';
      for (final c in _controllers) c.clear();
    });
  }

  void _saveEntry() {
    final values = <String>[];
    for (var i = 0; i < _fields.length; i++) {
      if (_fields[i].isLinks) {
        final json = _linksJson.trim();
        values.add(json == '[]' || json.isEmpty ? '' : json);
      } else {
        values.add(_controllers[i].text.trim());
      }
    }
    if (values.every((v) => v.isEmpty)) return;
    setState(() {
      _entries.add(values);
      _editingIndex = null;
      _linksJson = '';
      for (final c in _controllers) c.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            for (var i = 0; i < _fields.length; i++)
              if (_fields[i].isLinks)
                LinksEditor(
                  initial: _linksJson,
                  hint: _fields[i].label,
                  onChanged: (v) => setState(() => _linksJson = v),
                )
              else
                TextField(controller: _controllers[i]),
            ElevatedButton(onPressed: _saveEntry, child: const Text('Add')),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('full sheet-like flow keeps link in entry', (tester) async {
    await tester.pumpWidget(const _Harness());

    await tester.enterText(find.byType(TextField).at(0), 'ShipLink');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add link'));
    await tester.pumpAndSettle();

    final urlFields = find.descendant(
      of: find.byType(LinksEditor),
      matching: find.byType(TextField),
    );
    await tester.enterText(urlFields.first, 'https://github.com/me/app');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    final state = tester.state<_HarnessState>(find.byType(_Harness));
    expect(state._entries, isNotEmpty);
    expect(state._entries.last.length, 4);
    expect(state._entries.last[3], contains('https://github.com/me/app'));
  });
}
