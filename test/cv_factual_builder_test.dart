import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/domain/cv/cv_factual_builder.dart';
import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/career_target.dart';
import 'package:nexora/domain/entities/cv_content.dart';
import 'package:nexora/domain/entities/profile_data.dart';

CareerDna dnaWithFacts() => CareerDna(
      targetRole: 'Flutter Developer',
      skills: const ['Dart', 'Flutter', 'Firebase', 'Git'],
      profile: ProfileData(
        summary: 'Built apps.',
        experience: const [
          ProfileExperience(role: 'Intern', company: 'ACME', years: 1)
        ],
        projects: const [
          ProfileProject(
              name: 'Delivery',
              description: 'Built a food delivery app. Integrated Google Maps for real-time tracking.',
              tech: ['Flutter', 'Dart'])
        ],
      ),
    );

void main() {
  test('fresh graduate (no experience) yields no experience section', () {
    final dna = CareerDna(profile: const ProfileData(summary: 'Student'));
    final c = CvFactualBuilder.build(dna);
    expect(c.experience, isEmpty);
    expect(c.sourceLabel, 'Factual CV');
  });

  test('build includes only known facts and preserves them', () {
    final dna = dnaWithFacts();
    final c = CvFactualBuilder.build(dna);
    expect(c.experience.single.role, 'Intern');
    expect(c.projects.single.name, 'Delivery');
  });

  test('project links are carried into the Factual CV content', () {
    final dna = CareerDna(
      profile: ProfileData(
        projects: [
          ProfileProject(
            name: 'ShipLink',
            description: 'Shipping app',
            tech: const ['Flutter'],
            links: [ProjectLink(url: 'https://github.com/me/app')],
          ),
        ],
      ),
    );
    final c = CvFactualBuilder.build(dna);
    expect(c.projects, hasLength(1));
    expect(c.projects.single.links, hasLength(1));
    expect(c.projects.single.links.single.url, 'https://github.com/me/app');
  });

  test('target influences header but never the facts', () {
    final dna = dnaWithFacts();
    final a = CvFactualBuilder.build(
        dna, target: CareerTarget(
            id: 't',
            userId: 'u',
            type: TargetType.job,
            role: 'Senior Flutter',
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1)));
    final b = CvFactualBuilder.build(dna);
    expect(a.header.title, 'Senior Flutter');
    expect(b.header.title, 'Flutter Developer');
    expect(a.experience, b.experience);
  });

  test('building a factual CV never mutates the source CareerDna', () {
    final dna = dnaWithFacts();
    CvFactualBuilder.build(dna);
    expect(dna.profile.experience.single.company, 'ACME');
  });

  group('skill categorization', () {
    test('categorizes skills into meaningful groups', () {
      final dna = dnaWithFacts();
      final c = CvFactualBuilder.build(dna);
      expect(c.skillGroups.length, greaterThan(1));
      final titles = c.skillGroups.map((g) => g.title).toList();
      expect(titles, contains('Programming & Languages'));
      expect(titles, contains('Backend & Databases'));
      expect(titles, contains('DevOps & Tools'));
    });

    test('each category contains relevant skills', () {
      final dna = CareerDna(
        skills: const ['Dart', 'Flutter', 'Firebase', 'PostgreSQL', 'Git', 'Docker'],
      );
      final c = CvFactualBuilder.build(dna);
      final programmingGroup = c.skillGroups.firstWhere((g) => g.title == 'Programming & Languages');
      expect(programmingGroup.skills, contains('Dart'));
      final frameworksGroup = c.skillGroups.firstWhere((g) => g.title == 'Frameworks & Architecture');
      expect(frameworksGroup.skills, contains('Flutter'));
      final backendGroup = c.skillGroups.firstWhere((g) => g.title == 'Backend & Databases');
      expect(backendGroup.skills, containsAll(['Firebase', 'PostgreSQL']));
    });

    test('empty skills yields no skill groups', () {
      final dna = CareerDna(profile: const ProfileData(summary: 'Student'));
      final c = CvFactualBuilder.build(dna);
      expect(c.skillGroups, isEmpty);
    });

    test('unknown skills go to Other category', () {
      final dna = CareerDna(skills: const ['CustomTool']);
      final c = CvFactualBuilder.build(dna);
      final otherGroup = c.skillGroups.firstWhere(
        (g) => g.title == 'Other',
        orElse: () => const CvSkillGroup(title: '', skills: []),
      );
      expect(otherGroup.skills, contains('CustomTool'));
    });
  });

  group('project bullet decomposition', () {
    test('decomposes multi-sentence description into bullets', () {
      final dna = CareerDna(
        profile: ProfileData(
          projects: const [
            ProfileProject(
              name: 'App',
              description: 'Built a mobile app. Integrated payment system. Deployed to production.',
              tech: ['Flutter'],
            ),
          ],
        ),
      );
      final c = CvFactualBuilder.build(dna);
      expect(c.projects.single.bullets.length, 3);
    });

    test('keeps single short description as one bullet', () {
      final dna = CareerDna(
        profile: ProfileData(
          projects: const [
            ProfileProject(name: 'App', description: 'A simple todo app', tech: ['Flutter']),
          ],
        ),
      );
      final c = CvFactualBuilder.build(dna);
      expect(c.projects.single.bullets, isNotEmpty);
    });

    test('empty description yields empty bullets', () {
      final dna = CareerDna(
        profile: ProfileData(
          projects: const [ProfileProject(name: 'App', tech: ['Flutter'])],
        ),
      );
      final c = CvFactualBuilder.build(dna);
      expect(c.projects.single.bullets, isEmpty);
    });
  });

  group('project links', () {
    test('project with valid URL preserves it', () {
      final dna = CareerDna(
        profile: ProfileData(projects: [
          ProfileProject(
            name: 'ShipLink',
            description: 'Shipping app',
            tech: const ['Flutter'],
            links: [ProjectLink(label: 'GitHub', url: 'https://github.com/me/ship')],
          ),
        ]),
      );
      final c = CvFactualBuilder.build(dna);
      expect(c.projects.single.links.single.url, 'https://github.com/me/ship');
      expect(c.projects.single.links.single.label, 'GitHub');
    });

    test('project without URL has no links', () {
      final dna = CareerDna(
        profile: ProfileData(projects: const [
          ProfileProject(name: 'App', description: 'An app', tech: ['Flutter']),
        ]),
      );
      final c = CvFactualBuilder.build(dna);
      expect(c.projects.single.links, isEmpty);
    });

    test('multiple projects keep URLs attached to correct project', () {
      final dna = CareerDna(
        profile: ProfileData(projects: [
          ProfileProject(
            name: 'Alpha',
            tech: const ['Dart'],
            links: [ProjectLink(url: 'https://alpha.com')],
          ),
          ProfileProject(name: 'Beta', tech: const ['Dart']),
          ProfileProject(
            name: 'Gamma',
            tech: const ['Dart'],
            links: [ProjectLink(url: 'https://gamma.com')],
          ),
        ]),
      );
      final c = CvFactualBuilder.build(dna);
      expect(c.projects[0].links.single.url, 'https://alpha.com');
      expect(c.projects[1].links, isEmpty);
      expect(c.projects[2].links.single.url, 'https://gamma.com');
    });

    test('non-coding project with URL renders correctly', () {
      final dna = CareerDna(
        profile: ProfileData(projects: [
          ProfileProject(
            name: 'Research Paper',
            description: 'Published paper on AI ethics',
            tech: const [],
            links: [ProjectLink(label: 'Paper', url: 'https://arxiv.org/abs/123')],
          ),
        ]),
      );
      final c = CvFactualBuilder.build(dna);
      expect(c.projects.single.links.single.url, 'https://arxiv.org/abs/123');
      expect(c.projects.single.links.single.label, 'Paper');
    });

    test('empty URL entries are filtered out', () {
      final dna = CareerDna(
        profile: ProfileData(projects: [
          ProfileProject(
            name: 'App',
            tech: const ['Flutter'],
            links: [
              ProjectLink(label: '', url: ''),
              ProjectLink(label: 'GitHub', url: 'https://github.com/me'),
            ],
          ),
        ]),
      );
      final c = CvFactualBuilder.build(dna);
      expect(c.projects.single.links, hasLength(1));
      expect(c.projects.single.links.single.url, 'https://github.com/me');
    });

    test('auto-label detects GitHub from URL', () {
      final dna = CareerDna(
        profile: ProfileData(projects: [
          ProfileProject(
            name: 'MyApp',
            tech: const ['Flutter'],
            links: [ProjectLink(url: 'https://github.com/user/myapp')],
          ),
        ]),
      );
      final c = CvFactualBuilder.build(dna);
      expect(c.projects.single.links.single.label, 'GitHub');
    });
  });

  group('target-aware prioritization', () {
    test('target reorders experience by relevance', () {
      final dna = CareerDna(
        profile: ProfileData(experience: [
          const ProfileExperience(role: 'Flutter Developer', company: 'FlutterCo', years: 3),
          const ProfileExperience(role: 'Backend Engineer', company: 'GoCorp', years: 2),
        ]),
      );
      final target = CareerTarget(
        id: 't', userId: 'u', type: TargetType.job,
        role: 'Flutter Developer',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      final c = CvFactualBuilder.build(dna, target: target);
      expect(c.experience.first.role, 'Flutter Developer');
    });

    test('target reorders projects by relevance', () {
      final dna = CareerDna(
        targetRole: 'Backend Developer',
        profile: ProfileData(projects: [
          ProfileProject(
            name: 'Flutter App',
            description: 'Mobile app',
            tech: const ['Flutter'],
          ),
          ProfileProject(
            name: 'API Server',
            description: 'Backend API',
            tech: const ['Node.js', 'PostgreSQL'],
          ),
        ]),
      );
      final target = CareerTarget(
        id: 't', userId: 'u', type: TargetType.job,
        role: 'Backend Developer',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      final c = CvFactualBuilder.build(dna, target: target);
      expect(c.projects.first.name, 'API Server');
    });

    test('no target keeps original order', () {
      final dna = dnaWithFacts();
      final c = CvFactualBuilder.build(dna);
      expect(c.experience.single.role, 'Intern');
    });
  });

  group('empty sections', () {
    test('empty experience is omitted', () {
      final dna = CareerDna(profile: const ProfileData(summary: 'Student'));
      final c = CvFactualBuilder.build(dna);
      expect(c.experience, isEmpty);
    });

    test('empty projects is omitted', () {
      final dna = CareerDna(profile: const ProfileData(summary: 'No projects'));
      final c = CvFactualBuilder.build(dna);
      expect(c.projects, isEmpty);
    });

    test('empty education is omitted', () {
      final dna = CareerDna(profile: const ProfileData(summary: 'No edu'));
      final c = CvFactualBuilder.build(dna);
      expect(c.education, isEmpty);
    });

    test('empty certifications is omitted', () {
      final dna = CareerDna(profile: const ProfileData(summary: 'No certs'));
      final c = CvFactualBuilder.build(dna);
      expect(c.certifications, isEmpty);
    });

    test('entries with empty names are filtered', () {
      final dna = CareerDna(
        profile: ProfileData(projects: const [
          ProfileProject(name: '', tech: ['Flutter']),
          ProfileProject(name: 'Real App', tech: ['Dart']),
        ]),
      );
      final c = CvFactualBuilder.build(dna);
      expect(c.projects, hasLength(1));
      expect(c.projects.single.name, 'Real App');
    });
  });

  group('new skill categories', () {
    test('Design & Prototyping category exists', () {
      final dna = CareerDna(skills: const ['Figma', 'UI/UX', 'Prototyping']);
      final c = CvFactualBuilder.build(dna);
      final designGroup = c.skillGroups.firstWhere(
        (g) => g.title == 'Design & Prototyping',
        orElse: () => const CvSkillGroup(title: '', skills: []),
      );
      expect(designGroup.skills, containsAll(['Figma', 'UI/UX', 'Prototyping']));
    });

    test('Mobile & Cross-Platform category exists', () {
      final dna = CareerDna(skills: const ['iOS', 'Android', 'Adaptive Layouts']);
      final c = CvFactualBuilder.build(dna);
      final mobileGroup = c.skillGroups.firstWhere(
        (g) => g.title == 'Mobile & Cross-Platform',
        orElse: () => const CvSkillGroup(title: '', skills: []),
      );
      expect(mobileGroup.skills, containsAll(['iOS', 'Android', 'Adaptive Layouts']));
    });

    test('Frameworks & Architecture has framework skills', () {
      final dna = CareerDna(skills: const ['React', 'Vue.js', 'Next.js', 'Tailwind']);
      final c = CvFactualBuilder.build(dna);
      final fwGroup = c.skillGroups.firstWhere(
        (g) => g.title == 'Frameworks & Architecture',
        orElse: () => const CvSkillGroup(title: '', skills: []),
      );
      expect(fwGroup.skills, containsAll(['React', 'Vue.js', 'Next.js', 'Tailwind']));
    });
  });
}
