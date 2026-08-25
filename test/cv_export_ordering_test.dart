import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/domain/cv/cv_pdf_renderer.dart';
import 'package:nexora/domain/cv/cv_section_ordering.dart';
import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/career_target.dart';
import 'package:nexora/domain/entities/cv_content.dart';
import 'package:nexora/features/main/presentation/studio/cv_preview.dart';

const _markers = [
  'PROFILE',
  'EXPERIENCE',
  'PROJECTS',
  'EDUCATION',
  'SKILLS',
  'CERTIFICATIONS',
  'ACHIEVEMENTS',
  'LANGUAGES',
];

String _markerOf(CvSection s) => switch (s) {
      CvSection.summary => 'PROFILE',
      CvSection.experience => 'EXPERIENCE',
      CvSection.projects => 'PROJECTS',
      CvSection.education => 'EDUCATION',
      CvSection.skills => 'SKILLS',
      CvSection.certifications => 'CERTIFICATIONS',
      CvSection.achievements => 'ACHIEVEMENTS',
      CvSection.languages => 'LANGUAGES',
    };

/// Decodes every FlateDecode page-content stream of the PDF into readable
/// text, in page order (/Type/Pages /Kids + each page's /Contents reference).
/// Fonts are embedded with Identity-H, so operators carry hex glyph IDs that
/// must be translated through each font's /ToUnicode CMap. Object slices come
/// from the xref table so binary streams can't fake "N 0 obj" boundaries.
List<String> extractPageTexts(List<int> bytes) {
  final raw = latin1.decode(bytes, allowInvalid: true);

  final starts = objectSlicesFromXref(raw);

  final rawContentByObj = <int, String>{};
  final cmapByObj = <int, Map<int, String>>{};
  final toUnicodeRefByFontObj = <int, int>{};
  final contentsRefByPageObj = <int, int>{};
  final fontResByPageObj = <int, Map<String, int>>{};

  for (var i = 1; i < starts.length; i++) {
    if (starts[i] < 0) continue;
    // Object body ends at the next live object (xref offsets are exact).
    var chunkEnd = raw.indexOf('%%EOF', starts[i]);
    for (var j = i + 1; j < starts.length; j++) {
      if (starts[j] >= 0) {
        chunkEnd = starts[j];
        break;
      }
    }
    if (chunkEnd < 0 || chunkEnd <= starts[i]) continue;
    final chunk = raw.substring(starts[i], chunkEnd);
    final objNum = i;

    // Page objects carry "/Type/Page" (never "/Type/Pages").
    if (RegExp(r'/Type/Page(?![s])').hasMatch(chunk)) {
      final ref =
          RegExp(r'/Contents (\d+) 0 R').firstMatch(chunk)?.group(1);
      if (ref != null) contentsRefByPageObj[objNum] = int.parse(ref);
      final fontDict =
          RegExp(r'/Font<<(.*?)>>', dotAll: true).firstMatch(chunk);
      if (fontDict != null) {
        fontResByPageObj[objNum] = {
          for (final m in RegExp(r'/(\w+)\s+(\d+) 0 R')
              .allMatches(fontDict.group(1)!))
            m.group(1)!: int.parse(m.group(2)!),
        };
      }
      continue;
    }

    // Font objects link to their ToUnicode CMaps.
    if (chunk.contains('/Type/Font')) {
      final tuRef =
          RegExp(r'/ToUnicode\s+(\d+) 0 R').firstMatch(chunk)?.group(1);
      if (tuRef != null) {
        toUnicodeRefByFontObj[objNum] = int.parse(tuRef);
      }
    }

    final streamMatch =
        RegExp(r'<<(.*?)>>\s*stream\r?\n', dotAll: true).firstMatch(chunk);
    if (streamMatch == null) continue;
    if (!streamMatch.group(1)!.contains('/FlateDecode')) continue;

    final dataStart = streamMatch.end;
    final dataEnd = chunk.indexOf('endstream', dataStart);
    if (dataEnd < 0 || dataEnd - dataStart > 8 * 1024 * 1024) continue;
    var segment = chunk.substring(dataStart, dataEnd);
    segment = segment.replaceFirst(RegExp(r'\r?\n$'), '');

    String inflated;
    try {
      inflated = latin1.decode(
          zlib.decode(segment.codeUnits),
          allowInvalid: true);
    } on FormatException {
      continue;
    } catch (_) {
      continue;
    }

    if (inflated.contains('beginbfchar') ||
        inflated.contains('beginbfrange')) {
      cmapByObj[objNum] = _parseCMap(inflated);
    } else if (inflated.contains('BT')) {
      rawContentByObj[objNum] = inflated;
    }
  }

  // Resolve font-resource name -> glyph map per page, then decode.
  String decodeContent(String content, Map<String, int>? fonts) {
    Map<int, String>? cmapFor(String res) {
      final obj = fonts?[res];
      final tu = obj == null ? null : toUnicodeRefByFontObj[obj];
      return tu == null ? null : cmapByObj[tu];
    }

    final buf = StringBuffer();
    var active = cmapFor('/F1');
    final tfRe = RegExp(r'/(\w+)\s+[\d.]+\s+Tf');
    final hexRe = RegExp(r'<([0-9A-Fa-f]+)>');
    for (final line in content.split(RegExp(r'\r?\n|(?=ET)'))) {
      final tf = tfRe.firstMatch(line);
      if (tf != null) active = cmapFor(tf.group(1)!);
      for (final hex in hexRe.allMatches(line).map((m) => m.group(1)!)) {
        buf.write(_decodeGlyphRun(hex, active));
        buf.write(' ');
      }
    }
    return buf.toString();
  }

  // dart_pdf emits exactly one /Pages tree node; its /Kids array defines
  // the authoritative page order.
  final kids =
      RegExp(r'/Kids\[(.*?)\]', dotAll: true).firstMatch(raw)?.group(1) ?? '';
  final kidNums = RegExp(r'(\d+) 0 R')
      .allMatches(kids)
      .map((m) => int.parse(m.group(1)!));

  return [
    for (final pageObj in kidNums)
      if (rawContentByObj.containsKey(contentsRefByPageObj[pageObj]))
        decodeContent(
          rawContentByObj[contentsRefByPageObj[pageObj]]!,
          fontResByPageObj[pageObj],
        ),
  ];
}

String _decodeGlyphRun(String hex, Map<int, String>? cmap) {
  if (cmap == null || cmap.isEmpty) return '';
  final buf = StringBuffer();
  for (var i = 0; i + 4 <= hex.length; i += 4) {
    final gid = int.parse(hex.substring(i, i + 4), radix: 16);
    buf.write(cmap[gid] ?? '');
  }
  return buf.toString();
}

/// Byte offsets indexed by object number ("i 0 obj"), -1 for free entries,
/// parsed from the classic xref table. Falls back to regex scanning when the
/// table cannot be parsed.
List<int> objectSlicesFromXref(String raw) {
  final sx = raw.lastIndexOf('startxref');
  if (sx < 0) return _fallbackObjectSlices(raw);
  final offMatch = RegExp(r'(\d+)')
      .firstMatch(raw.substring(sx, sx + 40 < raw.length ? sx + 40 : raw.length));
  if (offMatch == null) return _fallbackObjectSlices(raw);
  final off = int.parse(offMatch.group(1)!);
  if (off <= 0 || off >= raw.length) return _fallbackObjectSlices(raw);
  final tbl = raw.substring(off);
  final head = RegExp(r'xref\s+(\d+)\s+(\d+)').firstMatch(tbl);
  if (!tbl.startsWith('xref') || head == null) {
    return _fallbackObjectSlices(raw);
  }
  final firstObj = int.parse(head.group(1)!);
  final count = int.parse(head.group(2)!);
  if (firstObj != 0 || count <= 1) return _fallbackObjectSlices(raw);

  var pos = head.end;
  final offsets = List<int>.filled(count, -1);
  for (var k = 0; k < count; k++) {
    final e =
        RegExp(r'(\d{10})\s+(\d{5})\s+([fn])').firstMatch(tbl.substring(pos));
    if (e == null) break;
    if (k > 0 && e.group(3) == 'n') offsets[k] = int.parse(e.group(1)!);
    pos += e.end;
  }
  return offsets;
}

List<int> _fallbackObjectSlices(String raw) {
  final matches =
      RegExp(r'(?<=\s)(\d+) 0 obj').allMatches(raw).toList();
  var maxNum = 0;
  for (final m in matches) {
    maxNum = maxNum > int.parse(m.group(1)!)
        ? maxNum
        : int.parse(m.group(1)!);
  }
  final slices = List<int>.filled(maxNum + 1, -1);
  for (final m in matches) {
    final n = int.parse(m.group(1)!);
    if (slices[n] < 0) slices[n] = m.start;
  }
  return slices;
}

Map<int, String> _parseCMap(String s) {
  final map = <int, String>{};
  String utf16be(String hex) =>
      String.fromCharCode(int.parse(hex, radix: 16));

  for (final block in RegExp(r'beginbfchar(.*?)endbfchar', dotAll: true)
      .allMatches(s)) {
    for (final e in RegExp(r'<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>')
        .allMatches(block.group(1)!)) {
      map[int.parse(e.group(1)!, radix: 16)] = utf16be(e.group(2)!);
    }
  }

  for (final block in RegExp(r'beginbfrange(.*?)endbfrange', dotAll: true)
      .allMatches(s)) {
    final body = block.group(1)!;
    // <lo> <hi> <dstStart>
    for (final e in RegExp(
            r'<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>')
        .allMatches(body)) {
      final lo = int.parse(e.group(1)!, radix: 16);
      final hi = int.parse(e.group(2)!, radix: 16);
      final dst = int.parse(e.group(3)!, radix: 16);
      for (var g = lo; g <= hi && g - lo < 65536; g++) {
        map[g] = String.fromCharCode(dst + (g - lo));
      }
    }
    // <lo> <hi> [<u1> <u2> …]
    for (final e in RegExp(
            r'<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*\[(.*?)\]',
            dotAll: true)
        .allMatches(body)) {
      final lo = int.parse(e.group(1)!, radix: 16);
      final unis = RegExp(r'<([0-9A-Fa-f]+)>')
          .allMatches(e.group(3)!)
          .map((m) => utf16be(m.group(1)!))
          .toList();
      for (var k = 0; k < unis.length; k++) {
        map[lo + k] = unis[k];
      }
    }
  }
  return map;
}

/// Section titles in true document order, derived from decoded page streams.
List<String> pdfSectionOrder(List<int> bytes) {
  final pages = extractPageTexts(bytes);
  final seen = <String>{};
  final order = <String>[];
  for (final page in pages) {
    final hits = <(String, int)>[];
    for (final marker in _markers) {
      if (!seen.contains(marker)) {
        final idx = page.indexOf(marker);
        if (idx >= 0) hits.add((marker, idx));
      }
    }
    hits.sort((a, b) => a.$2.compareTo(b.$2));
    for (final hit in hits) {
      order.add(hit.$1);
      seen.add(hit.$1);
    }
  }
  return order;
}

final _fullContent = CvContent(
  header: CvHeader(
    name: 'Alex Doe',
    title: 'Software Engineer',
    email: 'alex@example.com',
    phone: '+1 555 010 000',
    location: 'Remote',
    links: ['github.com/alexdoe'],
  ),
  summary:
      'Versatile engineer with experience across product delivery, research '
      'and community work.',
  experience: [
    CvExperience(
      role: 'Engineer',
      company: 'Northgate Analytics',
      startDate: '2021',
      endDate: 'Present',
      bullets: ['Shipped the core pipeline used by enterprise customers.'],
    ),
  ],
  projects: [
    CvProject(
      name: 'Signal Lab',
      tech: ['Flutter'],
      bullets: ['Realtime dashboard experiment.'],
    ),
  ],
  education: [
    CvEducation(
        degree: 'BSc', field: 'Computing', institution: 'Metro U', year: '2021'),
  ],
  skillGroups: [
    CvSkillGroup(title: 'Core', skills: ['Dart', 'SQL']),
  ],
  certifications: [
    CvCertification(name: 'CCNA', issuer: 'Cisco', year: '2020'),
  ],
  achievements: [CvAchievement(text: 'Hackathon finalist.')],
  languages: [
    CvLanguage(name: 'English', level: 'Native'),
  ],
);

const _scenarios = <(String, CareerStage?, TargetType?)>[
  ('fresh graduate', CareerStage.freshGraduate, null),
  ('experienced default', null, null),
  ('career changer', CareerStage.careerChanger, null),
  ('academic target', null, TargetType.academicApplication),
];

List<String> _expectedOrder(CareerStage? stage, TargetType? targetType) =>
    CvSectionOrdering.orderedSectionsForStages(
      content: _fullContent,
      stage: stage,
      targetType: targetType,
    ).map(_markerOf).toList();

Future<List<String>> _previewOrder(
  WidgetTester tester, {
  CareerStage? stage,
  TargetType? targetType,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CvPreview(
            content: _fullContent,
            templateId: 'nexoraMinimal',
            stage: stage,
            targetType: targetType,
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  final tops = <String, double>{};
  for (final marker in _markers) {
    final finder = find.text(marker);
    if (finder.evaluate().isNotEmpty) {
      tops[marker] = tester.getRect(finder.first).top;
    }
  }
  final entries = tops.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  return entries.map((e) => e.key).toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('preview ordering equals exported PDF ordering', () {
    // The canonical expectation is derived from the same ordering source both
    // the preview and the export flow are wired to.
    for (final (name, stage, targetType) in _scenarios) {
      testWidgets('preview: $name', (tester) async {
        expect(await _previewOrder(tester, stage: stage, targetType: targetType),
            _expectedOrder(stage, targetType));
      });

      test('exported PDF: $name', () async {
        final bytes = await CvPdfRenderer.render(
          content: _fullContent,
          templateId: 'nexoraMinimal',
          stage: stage,
          targetType: targetType,
        );
        expect(pdfSectionOrder(bytes), _expectedOrder(stage, targetType),
            reason: 'exported PDF must match the preview order');
      });
    }
  });

  group('orphan section headers', () {
    // The filler pushes the EXPERIENCE heading close to the bottom of page 1
    // under naive layout; the heading must move together with its first item.
    CvContent boundaryCase(int extraSentences) => CvContent(
          header: _fullContent.header.copyWith(title: 'Platform Engineer'),
          summary:
              '$extraSentences. '
              '${List.filled(extraSentences, 'Delivery-focused engineer working across web and mobile platforms.').join(' ')}',
          experience: [
            CvExperience(
              role: 'Senior Engineer',
              company: 'Northgate Analytics',
              startDate: 'Feb 2021',
              endDate: 'Present',
              location: 'Remote',
              bullets: [
                'Owns ingestion services processing two billion events monthly.',
              ],
            ),
            CvExperience(
              role: 'Engineer',
              company: 'Bluepeak Systems',
              startDate: '2018',
              endDate: '2021',
              bullets: ['Built customer-facing reporting APIs.'],
            ),
          ],
          projects: _fullContent.projects,
          education: _fullContent.education,
          skillGroups: _fullContent.skillGroups,
          languages: _fullContent.languages,
        );

    test('heading never separates from its first item near a page break',
        () async {
      // Sweep filler sizes so a page boundary lands inside the EXPERIENCE
      // section gap region; every size that starts the section on a fresh
      // page must show heading + first item together.
      var exercisedBoundaries = 0;
      for (var n = 20; n <= 58; n++) {
        final bytes = await CvPdfRenderer.render(
          content: boundaryCase(n),
          templateId: 'nexoraMinimal',
        );
        final pages = extractPageTexts(bytes);
        expect(pages, isNotEmpty, reason: 'n=$n');

        final expPage = pages.indexWhere((p) => p.contains('EXPERIENCE'));
        final northgatePage =
            pages.indexWhere((p) => p.contains('Northgate'));
        expect(expPage, greaterThanOrEqualTo(0), reason: 'n=$n');
        expect(northgatePage, greaterThanOrEqualTo(0), reason: 'n=$n');

        if (pages.length < 2 || pages[expPage].contains('PROFILE')) {
          // Section did not begin a page; keep-with-head not applicable yet.
          continue;
        }
        exercisedBoundaries++;
        expect(pages[expPage].contains('Northgate'), isTrue,
            reason:
                'n=$n: EXPERIENCE heading begins a page without its first '
                'item (orphan header)');
      }
      expect(exercisedBoundaries, greaterThan(0),
          reason: 'fixture sweep never placed a section boundary at a page '
              'start – tune filler sizes');
    });

    test('no blank pages introduced by keep-with-head grouping', () async {
      for (var n = 20; n <= 36; n += 2) {
        final bytes = await CvPdfRenderer.render(
          content: boundaryCase(n),
          templateId: 'nexoraCompact',
        );
        final pages = extractPageTexts(bytes);
        for (var i = 0; i < pages.length; i++) {
          expect(pages[i].trim().length, greaterThan(40),
              reason: 'page ${i + 1} (n=$n) is blank');
        }
      }
    });
  });
}
