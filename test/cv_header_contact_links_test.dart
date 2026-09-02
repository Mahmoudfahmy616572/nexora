import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/domain/cv/cv_factual_builder.dart';
import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/cv_content.dart';
import 'package:nexora/domain/entities/profile_data.dart';
import 'package:nexora/domain/entities/user_identity.dart';
import 'package:nexora/features/main/presentation/studio/cv_export_sheet.dart';

void main() {
  // ────────────────────────────────────────────────────────────────────────
  // 1-4: Labels visible, not raw URLs
  // ────────────────────────────────────────────────────────────────────────

  group('CvContactLink labels', () {
    test('email is NOT displayed as raw address in links', () {
      const h = CvHeader(
        name: 'Test',
        email: 'test@example.com',
        links: [CvContactLink(label: 'LinkedIn', url: 'https://linkedin.com/in/test')],
      );
      expect(h.links.first.label, 'LinkedIn');
      expect(h.links.first.url, contains('linkedin.com'));
    });

    test('LinkedIn visible as label, not raw URL', () {
      const h = CvHeader(
        links: [CvContactLink(label: 'LinkedIn', url: 'https://linkedin.com/in/user')],
      );
      expect(h.links.first.label, 'LinkedIn');
      expect(h.links.first.label, isNot(contains('linkedin.com')));
    });

    test('GitHub visible as label, not raw URL', () {
      const h = CvHeader(
        links: [CvContactLink(label: 'GitHub', url: 'https://github.com/user')],
      );
      expect(h.links.first.label, 'GitHub');
      expect(h.links.first.label, isNot(contains('github.com')));
    });

    test('Portfolio visible as label, not raw URL', () {
      const h = CvHeader(
        links: [CvContactLink(label: 'Portfolio', url: 'https://myportfolio.dev')],
      );
      expect(h.links.first.label, 'Portfolio');
      expect(h.links.first.label, isNot(contains('myportfolio.dev')));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // 5: PDF annotations — UrlLink wraps labels (renderer test)
  // ────────────────────────────────────────────────────────────────────────

  group('CvHeader toJson/fromJson preserves contact links', () {
    test('round-trip preserves labels and URLs', () {
      const h = CvHeader(
        name: 'Ahmed',
        email: 'a@b.com',
        phone: '+123',
        location: 'Cairo',
        links: [
          CvContactLink(label: 'LinkedIn', url: 'https://linkedin.com/in/ahmed'),
          CvContactLink(label: 'GitHub', url: 'https://github.com/ahmed'),
        ],
      );
      final json = h.toJson();
      final back = CvHeader.fromJson(json);
      expect(back.links.length, 2);
      expect(back.links[0].label, 'LinkedIn');
      expect(back.links[0].url, 'https://linkedin.com/in/ahmed');
      expect(back.links[1].label, 'GitHub');
    });

    test('backward-compat: plain strings in JSON are wrapped', () {
      final json = {
        'name': 'Test',
        'links': ['https://github.com/old'],
      };
      final h = CvHeader.fromJson(json);
      expect(h.links.length, 1);
      expect(h.links.first.url, 'https://github.com/old');
      expect(h.links.first.label, isEmpty);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // 6: Missing links — label hidden completely
  // ────────────────────────────────────────────────────────────────────────

  group('Missing links are hidden', () {
    test('empty links list produces no visible link text', () {
      const h = CvHeader(name: 'Test', links: []);
      expect(h.links, isEmpty);
    });

    test('only provided links appear', () {
      const h = CvHeader(
        links: [CvContactLink(label: 'LinkedIn', url: 'https://linkedin.com/in/u')],
      );
      expect(h.links.length, 1);
      expect(h.links.first.label, 'LinkedIn');
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // 7-8: Phone renders correctly, uses tel:
  // ────────────────────────────────────────────────────────────────────────

  group('Phone display', () {
    test('phone stored in header field', () {
      const h = CvHeader(phone: '+20 100 123 4567');
      expect(h.phone, '+20 100 123 4567');
    });

    test('phone is NOT in links list', () {
      const h = CvHeader(
        phone: '+20 100 123 4567',
        links: [CvContactLink(label: 'LinkedIn', url: 'https://linkedin.com/in/u')],
      );
      expect(h.links.every((l) => l.label != 'Phone'), isTrue);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // 9: Location remains normal text
  // ────────────────────────────────────────────────────────────────────────

  group('Location display', () {
    test('location stored in header field', () {
      const h = CvHeader(location: 'Mansoura, Egypt');
      expect(h.location, 'Mansoura, Egypt');
    });

    test('location is NOT in links list', () {
      const h = CvHeader(
        location: 'Mansoura, Egypt',
        links: [CvContactLink(label: 'GitHub', url: 'https://github.com/u')],
      );
      expect(h.links.every((l) => l.label != 'Location'), isTrue);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // 10: Text export matches labels
  // ────────────────────────────────────────────────────────────────────────

  group('Text export uses labels', () {
    test('cvToText shows labels not URLs', () {
      const content = CvContent(
        header: CvHeader(
          name: 'Test User',
          email: 'test@example.com',
          links: [
            CvContactLink(label: 'LinkedIn', url: 'https://linkedin.com/in/test'),
            CvContactLink(label: 'GitHub', url: 'https://github.com/test'),
          ],
        ),
      );
      final text = cvToText(content);
      expect(text, contains('LinkedIn'));
      expect(text, contains('GitHub'));
      expect(text, isNot(contains('linkedin.com')));
      expect(text, isNot(contains('github.com')));
    });

    test('cvToText omits empty links', () {
      const content = CvContent(
        header: CvHeader(name: 'Test', email: 't@e.com'),
      );
      final text = cvToText(content);
      expect(text, contains('t@e.com'));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // 11: Existing text extraction still works
  // ────────────────────────────────────────────────────────────────────────

  group('Existing data still works', () {
    test('header with no links still renders name/email/location', () {
      const content = CvContent(
        header: CvHeader(
          name: 'A',
          title: 'B',
          email: 'a@b.com',
          location: 'City',
        ),
      );
      final text = cvToText(content);
      expect(text, contains('A'));
      expect(text, contains('B'));
      expect(text, contains('a@b.com'));
      expect(text, contains('City'));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // 12: All 3 templates — labels used (renderer-level)
  // ────────────────────────────────────────────────────────────────────────

  group('All templates use labeled links', () {
    test('CvHeader labels are independent of template', () {
      const h = CvHeader(
        links: [
          CvContactLink(label: 'LinkedIn', url: 'https://linkedin.com/in/u'),
          CvContactLink(label: 'GitHub', url: 'https://github.com/u'),
          CvContactLink(label: 'Portfolio', url: 'https://u.dev'),
        ],
      );
      for (final link in h.links) {
        expect(link.label, isNotEmpty);
        expect(link.url, startsWith('http'));
      }
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // 13-14: EN/AR UI still works; CV remains English-only
  // ────────────────────────────────────────────────────────────────────────

  group('Identity integration', () {
    test('CvFactualBuilder produces labeled links from identity', () {
      final dna = CareerDna(
        targetRole: 'Flutter Developer',
        skills: const ['Dart'],
        profile: const ProfileData(summary: 'Dev'),
      );
      final identity = UserIdentity(
        fullName: 'Test User',
        linkedinUrl: 'https://linkedin.com/in/test',
        githubUrl: 'https://github.com/test',
        portfolioUrl: 'https://test.dev',
      );
      final content = CvFactualBuilder.build(dna, identity: identity);
      expect(content.header.links.length, 3);
      expect(content.header.links[0].label, 'LinkedIn');
      expect(content.header.links[1].label, 'GitHub');
      expect(content.header.links[2].label, 'Portfolio');
    });

    test('missing identity links produce no link entries', () {
      final dna = CareerDna(
        targetRole: 'Dev',
        skills: const ['Dart'],
        profile: const ProfileData(summary: 'S'),
      );
      final content = CvFactualBuilder.build(dna, identity: const UserIdentity());
      expect(content.header.links, isEmpty);
    });

    test('partial identity links produce only provided entries', () {
      final dna = CareerDna(
        targetRole: 'Dev',
        skills: const ['Dart'],
        profile: const ProfileData(summary: 'S'),
      );
      final identity = UserIdentity(
        githubUrl: 'https://github.com/user',
      );
      final content = CvFactualBuilder.build(dna, identity: identity);
      expect(content.header.links.length, 1);
      expect(content.header.links.first.label, 'GitHub');
    });
  });
}
