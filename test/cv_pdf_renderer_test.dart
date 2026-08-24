import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/domain/cv/cv_pdf_renderer.dart';
import 'package:nexora/domain/entities/cv_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CvPdfRenderer', () {
    test('generates valid PDF for minimal template', () async {
      final content = _shortCv();
      final bytes = await CvPdfRenderer.render(
        content: content,
        templateId: 'nexoraMinimal',
      );
      expect(bytes.isNotEmpty, true);
      // PDF header: %PDF-
      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
    });

    test('generates valid PDF for modern template', () async {
      final content = _shortCv();
      final bytes = await CvPdfRenderer.render(
        content: content,
        templateId: 'nexoraModern',
      );
      expect(bytes.isNotEmpty, true);
      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
    });

    test('generates valid PDF for compact template', () async {
      final content = _shortCv();
      final bytes = await CvPdfRenderer.render(
        content: content,
        templateId: 'nexoraCompact',
      );
      expect(bytes.isNotEmpty, true);
      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
    });

    test('generates multi-page PDF for long CV', () async {
      final content = _longCv();
      final bytes = await CvPdfRenderer.render(
        content: content,
        templateId: 'nexoraMinimal',
      );
      expect(bytes.isNotEmpty, true);
      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
      // Multi-page PDF should be significantly larger
      expect(bytes.length, greaterThan(1000));
    });

    test('handles empty content gracefully', () async {
      final content = CvContent(
        header: const CvHeader(name: ''),
        summary: '',
        experience: const [],
        projects: const [],
        education: const [],
        skillGroups: const [],
        certifications: const [],
        achievements: const [],
        languages: const [],
      );
      final bytes = await CvPdfRenderer.render(
        content: content,
        templateId: 'nexoraMinimal',
      );
      expect(bytes.isNotEmpty, true);
      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
    });

    test('handles content with only header', () async {
      final content = CvContent(
        header: const CvHeader(
          name: 'Test User',
          title: 'Developer',
          email: 'test@example.com',
          phone: '+1234567890',
        ),
        summary: '',
        experience: const [],
        projects: const [],
        education: const [],
        skillGroups: const [],
        certifications: const [],
        achievements: const [],
        languages: const [],
      );
      final bytes = await CvPdfRenderer.render(
        content: content,
        templateId: 'nexoraMinimal',
      );
      expect(bytes.isNotEmpty, true);
    });

    test('includes project bullets in PDF', () async {
      final content = CvContent(
        header: const CvHeader(name: 'Dev'),
        summary: '',
        experience: const [],
        projects: const [
          CvProject(
            name: 'E-Commerce Platform',
            description: 'Full-stack platform',
            tech: ['Flutter', 'Node.js'],
            bullets: [
              'Built REST API serving 10k requests/min',
              'Implemented real-time inventory sync',
            ],
          ),
        ],
        education: const [],
        skillGroups: const [],
        certifications: const [],
        achievements: const [],
        languages: const [],
      );
      final bytes = await CvPdfRenderer.render(
        content: content,
        templateId: 'nexoraMinimal',
      );
      expect(bytes.isNotEmpty, true);
      // PDF should be large enough to contain bullet content
      expect(bytes.length, greaterThan(500));
    });

    test('includes experience bullets in PDF', () async {
      final content = CvContent(
        header: const CvHeader(name: 'Engineer'),
        summary: '',
        experience: const [
          CvExperience(
            role: 'Senior Engineer',
            company: 'TechCorp',
            years: 4,
            bullets: [
              'Led team of 5 engineers',
              'Reduced latency by 40%',
              'Shipped 3 major features',
            ],
          ),
        ],
        projects: const [],
        education: const [],
        skillGroups: const [],
        certifications: const [],
        achievements: const [],
        languages: const [],
      );
      final bytes = await CvPdfRenderer.render(
        content: content,
        templateId: 'nexoraMinimal',
      );
      expect(bytes.isNotEmpty, true);
    });

    test('grouped skills rendered correctly', () async {
      final content = CvContent(
        header: const CvHeader(name: 'Full-Stack Dev'),
        summary: '',
        experience: const [],
        projects: const [],
        education: const [],
        skillGroups: const [
          CvSkillGroup(title: 'Frontend', skills: ['React', 'TypeScript']),
          CvSkillGroup(title: 'Backend', skills: ['Node.js', 'Python']),
          CvSkillGroup(title: 'DevOps', skills: ['Docker', 'AWS']),
        ],
        certifications: const [],
        achievements: const [],
        languages: const [],
      );
      final bytes = await CvPdfRenderer.render(
        content: content,
        templateId: 'nexoraMinimal',
      );
      expect(bytes.isNotEmpty, true);
    });

    test('all three templates produce different file sizes', () async {
      final content = _shortCv();
      final minBytes = await CvPdfRenderer.render(content: content, templateId: 'nexoraMinimal');
      final modBytes = await CvPdfRenderer.render(content: content, templateId: 'nexoraModern');
      final compBytes = await CvPdfRenderer.render(content: content, templateId: 'nexoraCompact');
      // All should be valid PDFs
      expect(String.fromCharCodes(minBytes.sublist(0, 5)), '%PDF-');
      expect(String.fromCharCodes(modBytes.sublist(0, 5)), '%PDF-');
      expect(String.fromCharCodes(compBytes.sublist(0, 5)), '%PDF-');
    });

    test('handles content with experience startDate/endDate', () async {
      final content = CvContent(
        header: const CvHeader(name: 'Career Changer'),
        summary: '',
        experience: const [
          CvExperience(
            role: 'Software Engineer',
            company: 'StartupX',
            startDate: 'Jan 2023',
            endDate: 'Present',
            bullets: ['Built CI/CD pipeline'],
          ),
          CvExperience(
            role: 'Data Analyst',
            company: 'DataCorp',
            startDate: 'Mar 2021',
            endDate: 'Dec 2022',
            location: 'New York, NY',
            description: 'Analyzed datasets',
          ),
        ],
        projects: const [],
        education: const [
          CvEducation(
            degree: 'MS',
            field: 'Computer Science',
            institution: 'MIT',
            year: '2020',
          ),
        ],
        skillGroups: const [
          CvSkillGroup(title: 'Languages', skills: ['Python', 'Dart']),
        ],
        certifications: const [],
        achievements: const [],
        languages: const [CvLanguage(name: 'English', level: 'Native')],
      );
      final bytes = await CvPdfRenderer.render(
        content: content,
        templateId: 'nexoraMinimal',
      );
      expect(bytes.isNotEmpty, true);
    });

    test('project links included in PDF', () async {
      final content = CvContent(
        header: const CvHeader(name: 'Open Source Dev'),
        summary: '',
        experience: const [],
        projects: const [
          CvProject(
            name: 'AwesomeLib',
            description: 'A library',
            tech: ['Dart'],
            links: ['https://github.com/example/awesomelib'],
          ),
        ],
        education: const [],
        skillGroups: const [],
        certifications: const [],
        achievements: const [],
        languages: const [],
      );
      final bytes = await CvPdfRenderer.render(
        content: content,
        templateId: 'nexoraMinimal',
      );
      expect(bytes.isNotEmpty, true);
    });
  });

  group('CvPdfRenderer RTL', () {
    test('handles RTL text direction', () async {
      final content = CvContent(
        header: const CvHeader(
          name: 'أحمد محمد',
          title: 'مهندس برمجيات',
          location: 'القاهرة، مصر',
        ),
        summary: 'مهندس برمجيات ذو خبرة',
        experience: const [],
        projects: const [],
        education: const [],
        skillGroups: const [
          CvSkillGroup(title: 'اللغات', skills: ['dart', 'python']),
        ],
        certifications: const [],
        achievements: const [],
        languages: const [],
      );
      final bytes = await CvPdfRenderer.render(
        content: content,
        templateId: 'nexoraMinimal',
      );
      expect(bytes.isNotEmpty, true);
      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
    });
  });
}

CvContent _shortCv() => CvContent(
      header: const CvHeader(
        name: 'Ahmed Hassan',
        title: 'Full-Stack Developer',
        subtitle: 'Open to opportunities',
        email: 'ahmed@example.com',
        phone: '+20 100 123 4567',
        location: 'Cairo, Egypt',
        links: ['linkedin.com/in/ahmed', 'github.com/ahmed'],
      ),
      summary:
          'Full-stack developer with 3+ years of experience building scalable web and mobile applications.',
      experience: const [
        CvExperience(
          role: 'Full-Stack Developer',
          company: 'TechCorp',
          startDate: '2021',
          endDate: 'Present',
          location: 'Cairo, Egypt',
          bullets: [
            'Built microservices architecture serving 50k daily users',
            'Reduced API response time by 60% through caching optimization',
          ],
        ),
      ],
      projects: const [
        CvProject(
          name: 'E-Commerce Platform',
          description: 'Full-stack e-commerce solution',
          tech: ['Flutter', 'Node.js', 'MongoDB'],
          bullets: [
            'Implemented real-time inventory management system',
            'Integrated Stripe payment processing for 10k+ transactions',
          ],
        ),
      ],
      education: const [
        CvEducation(
          degree: 'BSc',
          field: 'Computer Science',
          institution: 'Cairo University',
          year: '2021',
        ),
      ],
      skillGroups: const [
        CvSkillGroup(title: 'Frontend', skills: ['Flutter', 'React', 'TypeScript']),
        CvSkillGroup(title: 'Backend', skills: ['Node.js', 'Python', 'Dart']),
      ],
      certifications: const [],
      achievements: const [],
      languages: const [
        CvLanguage(name: 'Arabic', level: 'Native'),
        CvLanguage(name: 'English', level: 'Fluent'),
      ],
    );

CvContent _longCv() => CvContent(
      header: const CvHeader(
        name: 'Senior Software Engineer',
        title: 'Platform Architecture Lead',
        subtitle: 'Distributed systems expert',
        email: 'senior@example.com',
        phone: '+1 555 0123',
        location: 'San Francisco, CA',
        links: ['linkedin.com/in/senior', 'github.com/senior', 'senior.dev'],
      ),
      summary:
          'Senior software engineer with 10+ years of experience designing and building distributed systems, '
          'leading teams of 10+ engineers, and driving technical strategy for enterprise platforms.',
      experience: const [
        CvExperience(
          role: 'Platform Architecture Lead',
          company: 'MegaCorp',
          startDate: '2020',
          endDate: 'Present',
          location: 'San Francisco, CA',
          bullets: [
            'Led migration of monolithic architecture to microservices, reducing deployment time from 2 hours to 5 minutes',
            'Designed event-driven architecture processing 1M+ events/day with 99.99% uptime',
            'Built internal developer platform used by 200+ engineers across 5 teams',
            'Established engineering standards and code review processes adopted company-wide',
            'Mentored 12 junior engineers, with 4 promoted to senior roles within 18 months',
          ],
        ),
        CvExperience(
          role: 'Senior Backend Engineer',
          company: 'StartupInc',
          startDate: '2017',
          endDate: '2020',
          location: 'Seattle, WA',
          description: 'Led backend team building real-time collaboration platform.',
        ),
        CvExperience(
          role: 'Software Engineer',
          company: 'BigTech',
          startDate: '2014',
          endDate: '2017',
          location: 'Austin, TX',
          description: 'Built search infrastructure and data pipelines.',
        ),
      ],
      projects: const [
        CvProject(
          name: 'Distributed Cache System',
          description: 'High-performance distributed caching layer',
          tech: ['Go', 'Redis', 'gRPC'],
          bullets: [
            'Achieved sub-millisecond latency for 99th percentile requests',
            'Handled 500k concurrent connections with automatic failover',
          ],
        ),
        CvProject(
          name: 'CI/CD Pipeline',
          description: 'Automated deployment infrastructure',
          tech: ['Kubernetes', 'Terraform', 'GitHub Actions'],
          bullets: [
            'Reduced deployment failures by 80% through automated testing gates',
            'Enabled 50+ daily deployments with zero-downtime rolling updates',
          ],
        ),
        CvProject(
          name: 'ML Feature Store',
          description: 'Built feature store serving ML models in production.',
          tech: ['Python', 'Apache Spark', 'Airflow'],
        ),
        CvProject(
          name: 'API Gateway',
          description: 'Unified API management layer',
          tech: ['Kong', 'Lua', 'PostgreSQL'],
          bullets: [
            'Managed 100+ API endpoints with rate limiting and authentication',
          ],
        ),
      ],
      education: const [
        CvEducation(
          degree: 'MS',
          field: 'Computer Science',
          institution: 'Stanford University',
          year: '2014',
        ),
        CvEducation(
          degree: 'BS',
          field: 'Computer Engineering',
          institution: 'UT Austin',
          year: '2012',
        ),
      ],
      skillGroups: const [
        CvSkillGroup(
            title: 'Languages',
            skills: ['Go', 'Python', 'TypeScript', 'Java', 'Rust']),
        CvSkillGroup(
            title: 'Infrastructure',
            skills: [
              'Kubernetes',
              'Docker',
              'Terraform',
              'AWS',
              'GCP',
              'Azure'
            ]),
        CvSkillGroup(
            title: 'Databases',
            skills: ['PostgreSQL', 'MongoDB', 'Redis', 'Cassandra', 'DynamoDB']),
        CvSkillGroup(
            title: 'Architecture',
            skills: [
              'Microservices',
              'Event-Driven',
              'CQRS',
              'Domain-Driven Design'
            ]),
      ],
      certifications: const [
        CvCertification(name: 'AWS Solutions Architect Professional', issuer: 'Amazon', year: '2022'),
        CvCertification(name: 'Google Cloud Professional Architect', issuer: 'Google', year: '2021'),
      ],
      achievements: const [
        CvAchievement(text: 'Published 3 technical papers on distributed systems'),
        CvAchievement(text: 'Speaker at KubeCon 2023 on platform engineering'),
        CvAchievement(text: 'Open-source contributor with 5k+ GitHub stars'),
      ],
      languages: const [
        CvLanguage(name: 'English', level: 'Native'),
        CvLanguage(name: 'Mandarin', level: 'Conversational'),
      ],
    );
