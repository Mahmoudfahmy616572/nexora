import 'entities/profile_data.dart';

/// A career domain the user can pick from — no CV or prior writing required.
///
/// Each value maps to a ready-made, editable draft so a user who has nothing
/// filled in yet still gets a complete, believable starting profile.
enum Interest {
  programming,
  design,
  writing,
  data,
  marketing,
  teaching,
  business,
  engineering,
  medicine,
  law,
  finance,
  psychology,
  photography,
  music,
  sports,
  hospitality,
  agriculture,
  science,
  sales,
}

/// What the user wants the profile for. Shapes the generated summary tone.
enum Goal {
  internship,
  scholarship,
  job,
  freelance,
}

/// The result of [generateProfile]: a full [ProfileData] plus the flat skills
/// list the rest of the app uses for AI matching.
class GeneratedProfile {
  const GeneratedProfile({required this.data, required this.skills});

  final ProfileData data;
  final List<String> skills;
}

/// Parses the hosted AI edge function's `{ skills, profile }` response into a
/// [GeneratedProfile]. Throws if the shape is unusable so the caller can fall
/// back to the local [generateProfile].
GeneratedProfile parseAiProfile(Map<String, dynamic> json) {
  final profileJson = json['profile'];
  final skillsJson = json['skills'];
  if (profileJson is! Map<String, dynamic> || skillsJson is! List) {
    throw StateError('AI response missing profile/skills');
  }
  return GeneratedProfile(
    data: ProfileData.fromJson(profileJson),
    skills: [for (final s in skillsJson) s as String],
  );
}

/// Substring (lowercased, English or Arabic) → a preset [Interest]. Letting the
/// user's own sentence quietly add domains means we capture more signal with
/// zero extra effort from them.
const Map<String, Interest> _domainKeywords = {
  'flutter': Interest.programming,
  'dart': Interest.programming,
  'design': Interest.design,
  'تصميم': Interest.design,
  'writing': Interest.writing,
  'كتاب': Interest.writing,
  'data': Interest.data,
  'بيانات': Interest.data,
  'marketing': Interest.marketing,
  'تسويق': Interest.marketing,
  'teach': Interest.teaching,
  'تدريس': Interest.teaching,
  'business': Interest.business,
  'بيزنس': Interest.business,
  'أعمال': Interest.business,
  'engineer': Interest.engineering,
  'هندس': Interest.engineering,
  'medicine': Interest.medicine,
  'طب': Interest.medicine,
  'doctor': Interest.medicine,
  'law': Interest.law,
  'قانون': Interest.law,
  'lawyer': Interest.law,
  'finance': Interest.finance,
  'مالية': Interest.finance,
  'محاسبة': Interest.finance,
  'accounting': Interest.finance,
  'psychology': Interest.psychology,
  'علم نفس': Interest.psychology,
  'photo': Interest.photography,
  'تصوير': Interest.photography,
  'music': Interest.music,
  'موسيق': Interest.music,
  'sport': Interest.sports,
  'رياض': Interest.sports,
  'hospitality': Interest.hospitality,
  'فنادق': Interest.hospitality,
  'agriculture': Interest.agriculture,
  'زراع': Interest.agriculture,
  'science': Interest.science,
  'علوم': Interest.science,
  'sales': Interest.sales,
  'مبيعات': Interest.sales,
};

/// Example "about me" lines shown on the Smart Builder's sentence step. Each is
/// tied to a domain so the prompts the user sees actually relate to what they
/// picked (or typed) instead of being fixed.
const Map<Interest, List<String>> _interestExamples = {
  Interest.programming: [
    'I like building apps and learning new tech',
    'I enjoy solving logic puzzles',
    'I want to create tools that help people',
  ],
  Interest.design: [
    'I enjoy designing clean interfaces',
    'I love turning ideas into visuals',
    'I care about how things feel to use',
  ],
  Interest.writing: [
    'I like writing stories and articles',
    'I enjoy explaining hard things simply',
    'Words are how I express myself',
  ],
  Interest.data: [
    'I want to analyze data and tell stories with it',
    'I like finding patterns in numbers',
    'I enjoy making sense of messy information',
  ],
  Interest.marketing: [
    'I enjoy creating campaigns people remember',
    'I like understanding what makes people click',
    'I want to grow brands online',
  ],
  Interest.teaching: [
    'I love helping others understand things',
    'I enjoy explaining concepts clearly',
    'Teaching helps me learn too',
  ],
  Interest.business: [
    'I like organizing projects and teams',
    'I enjoy turning ideas into plans',
    'I want to build something of my own',
  ],
  Interest.engineering: [
    'I like building things that actually work',
    'I enjoy solving hands-on problems',
    'I love seeing a prototype come to life',
  ],
  Interest.medicine: [
    'I want to help patients get better',
    'I’m drawn to science and care',
    'I enjoy learning how the body works',
  ],
  Interest.law: [
    'I like arguing cases and finding the truth',
    'I enjoy reading and analyzing rules',
    'Justice and order matter to me',
  ],
  Interest.finance: [
    'I enjoy making sense of money and markets',
    'I like building models in Excel',
    'I want to help others plan financially',
  ],
  Interest.psychology: [
    'I’m fascinated by how people think',
    'I enjoy listening and helping others',
    'Human behavior really interests me',
  ],
  Interest.photography: [
    'I love capturing moments through a lens',
    'I enjoy editing photos into stories',
    'Visuals are how I see the world',
  ],
  Interest.music: [
    'I love performing and creating songs',
    'Music is how I express myself',
    'I enjoy collaborating on tracks',
  ],
  Interest.sports: [
    'I love training and pushing my limits',
    'I enjoy being part of a team',
    'I want to help others get fit',
  ],
  Interest.hospitality: [
    'I enjoy making guests feel welcome',
    'I like organizing smooth events',
    'People’s happiness matters to me',
  ],
  Interest.agriculture: [
    'I care about where food comes from',
    'I enjoy working with the land',
    'I want greener, smarter farming',
  ],
  Interest.science: [
    'I love running experiments and learning',
    'I enjoy digging into how things work',
    'Research really excites me',
  ],
  Interest.sales: [
    'I enjoy connecting people with what they need',
    'I like the challenge of hitting targets',
    'Talking to people energizes me',
  ],
};

const List<String> _genericExamples = [
  'I’m not sure yet, but I like creating things',
  'I enjoy learning new skills',
  'I want to find where I fit',
];

String _goalExample(Goal goal) => switch (goal) {
      Goal.internship => 'I’m looking for an internship to learn from real teams',
      Goal.scholarship => 'I’m applying for scholarships to keep growing',
      Goal.job => 'I want an entry-level job to start my career',
      Goal.freelance => 'I’m building a freelance portfolio',
    };

/// Returns example "about me" prompts tailored to the chosen domains, goals,
/// and any custom domain the user typed. This is what the Smart Builder shows
/// on the sentence step so the suggestions always relate to the user's pick.
List<String> buildSuggestionPrompts({
  required Set<Interest> interests,
  required List<String> customInterests,
  required Set<Goal> goals,
}) {
  final prompts = <String>[];
  for (final interest in interests) {
    prompts.addAll(_interestExamples[interest] ?? const []);
  }
  for (final custom in customInterests) {
    final title = _titleCase(custom);
    prompts.addAll([
      'I’m really into $title and want to learn more',
      'I enjoy working on $title projects in my free time',
      'I’d love to build a career in $title',
    ]);
  }
  for (final goal in goals) {
    prompts.add(_goalExample(goal));
  }
  if (prompts.isEmpty) prompts.addAll(_genericExamples);
  return prompts.toSet().toList();
}

/// Builds a complete, editable Career DNA draft from a few taps, optional custom
/// domains, and an optional free-text sentence — the offline engine behind the
/// Smart Builder.
///
/// This is the local fallback (mirrors how Analyze works offline). When an AI
/// edge function is available it can replace [generateProfile] with a hosted
/// call; the UI only depends on the returned [GeneratedProfile].
GeneratedProfile generateProfile({
  required Set<Interest> interests,
  List<String> customInterests = const [],
  required Set<Goal> goals,
  String? sentence,
}) {
  final picked = <Interest>{...interests};

  // Quietly enrich from the sentence so a single line captures more than skill
  // keywords — it can also surface a whole domain the user didn't tap.
  final text = sentence?.toLowerCase() ?? '';
  for (final entry in _domainKeywords.entries) {
    if (text.contains(entry.key)) picked.add(entry.value);
  }

  final effective = (picked.isNotEmpty || customInterests.isNotEmpty) ? picked : {Interest.programming};

  final skills = <String>{};
  final experience = <ProfileExperience>[];
  final projects = <ProfileProject>[];
  final education = <ProfileEducation>[];
  final certifications = <ProfileCertification>[];
  final achievements = <String>[];

  for (final interest in effective) {
    final blueprint = _blueprint(interest);
    skills.addAll(blueprint.skills);
    experience.add(blueprint.experience);
    projects.add(blueprint.project);
    education.add(blueprint.education);
    certifications.add(ProfileCertification.fromString(blueprint.certification));
    achievements.add(blueprint.achievement);
  }

  for (final custom in customInterests) {
    final blueprint = _blueprintForCustom(custom);
    skills.addAll(blueprint.skills);
    experience.add(blueprint.experience);
    projects.add(blueprint.project);
    education.add(blueprint.education);
    certifications.add(ProfileCertification.fromString(blueprint.certification));
    achievements.add(blueprint.achievement);
  }

  skills.addAll(_extractFromSentence(sentence));

  final roles = <String>[
    for (final interest in effective) _blueprint(interest).role,
    for (final custom in customInterests) 'aspiring ${_titleCase(custom)} professional',
  ];
  final topSkills = skills.take(3).toList();
  final summary = _buildSummary(
    roles: roles,
    goals: goals,
    topSkills: topSkills,
    sentence: sentence,
  );

  return GeneratedProfile(
    skills: skills.toList(),
    data: ProfileData(
      summary: summary,
      experience: experience,
      projects: projects,
      education: education,
      certifications: certifications,
      achievements: achievements,
      languages: const ['Arabic', 'English'],
    ),
  );
}

String _buildSummary({
  required List<String> roles,
  required Set<Goal> goals,
  required List<String> topSkills,
  String? sentence,
}) {
  final roleText = roles.isEmpty
      ? 'motivated learner'
      : roles.length == 1
          ? roles.single
          : '${roles.take(roles.length - 1).join(', ')} and ${roles.last}';
  final skillsText = topSkills.join(', ');
  final goalText = goals.isEmpty
      ? 'exploring where to start'
      : goals.map(_goalPhrase).join(' and ');

  final buffer = StringBuffer()
    ..write('Motivated $roleText with hands-on practice in $skillsText. ')
    ..write('Currently $goalText, bringing curiosity, consistency, and a '
        'builder\'s mindset to every project.');

  final trimmed = _trimSentence(sentence);
  if (trimmed != null) {
    buffer.write(' $trimmed');
  }
  return buffer.toString();
}

String _goalPhrase(Goal goal) => switch (goal) {
      Goal.internship => 'seeking an internship to learn from real teams',
      Goal.scholarship => 'applying for scholarships to keep growing',
      Goal.job => 'looking for entry-level opportunities',
      Goal.freelance => 'building a freelance portfolio',
    };

/// Pulls a few extra skills out of the user's own words (English or Arabic).
Set<String> _extractFromSentence(String? sentence) {
  final found = <String>{};
  if (sentence == null || sentence.trim().isEmpty) return found;
  final text = sentence.toLowerCase();

  const keywords = {
    'flutter': 'Flutter',
    'دارت': 'Dart',
    'dart': 'Dart',
    'python': 'Python',
    'sql': 'SQL',
    'excel': 'Excel',
    'figma': 'Figma',
    'ui': 'UI/UX Design',
    'ux': 'UI/UX Design',
    'تصميم': 'UI/UX Design',
    'كتب': 'Content Writing',
    'writing': 'Content Writing',
    'copywriting': 'Copywriting',
    'marketing': 'Marketing',
    'تسويق': 'Marketing',
    'data': 'Data Analysis',
    'بيانات': 'Data Analysis',
    'git': 'Git',
    'rest': 'REST APIs',
  };

  for (final entry in keywords.entries) {
    if (text.contains(entry.key)) found.add(entry.value);
  }
  return found;
}

String? _trimSentence(String? sentence) {
  if (sentence == null) return null;
  final trimmed = sentence.trim();
  if (trimmed.isEmpty) return null;
  return trimmed.length > 140 ? '${trimmed.substring(0, 140)}…' : trimmed;
}

String _titleCase(String s) {
  final trimmed = s.trim();
  if (trimmed.isEmpty) return trimmed;
  return trimmed[0].toUpperCase() + trimmed.substring(1);
}

class _Blueprint {
  const _Blueprint({
    required this.role,
    required this.skills,
    required this.experience,
    required this.project,
    required this.education,
    required this.certification,
    required this.achievement,
  });

  final String role;
  final List<String> skills;
  final ProfileExperience experience;
  final ProfileProject project;
  final ProfileEducation education;
  final String certification;
  final String achievement;
}

/// Maps words inside a custom domain name (English or Arabic) to relevant
/// skills, so typing "Robotics", "Nursing" or "روبوتات" yields domain skills
/// instead of only generic ones. Substring match — first hit wins per key.
const Map<String, List<String>> _customDomainSkills = {
  'robot': ['Robotics', 'Arduino', 'Circuit Design', 'Python', 'Mechanical Assembly', 'Problem Solving'],
  'روبوت': ['Robotics', 'Arduino', 'Circuit Design', 'Python', 'Mechanical Assembly', 'Problem Solving'],
  'nurs': ['Patient Care', 'Vital Signs', 'Anatomy', 'Clinical Rotation', 'Empathy', 'Communication'],
  'تمريض': ['Patient Care', 'Vital Signs', 'Anatomy', 'Clinical Rotation', 'Empathy', 'Communication'],
  'medic': ['Patient Care', 'Anatomy', 'Clinical Skills', 'Empathy', 'Communication'],
  'طب': ['Patient Care', 'Anatomy', 'Clinical Skills', 'Empathy', 'Communication'],
  'cyber': ['Network Security', 'Penetration Testing', 'Cryptography', 'Linux', 'Threat Analysis'],
  'أمن': ['Network Security', 'Risk Assessment', 'Report Writing', 'Vigilance'],
  'security': ['Risk Assessment', 'Surveillance', 'Report Writing', 'Communication'],
  'ai': ['Machine Learning', 'Python', 'Data Analysis', 'Neural Networks', 'PyTorch'],
  'machine learning': ['Machine Learning', 'Python', 'Data Analysis', 'Model Training'],
  'ذكاء': ['Machine Learning', 'Python', 'Data Analysis', 'Neural Networks'],
  'graphic': ['Graphic Design', 'Illustrator', 'Photoshop', 'Typography', 'Branding'],
  'تصميم': ['Graphic Design', 'Branding', 'Typography', 'Visual Composition'],
  'design': ['Design Principles', 'Figma', 'Prototyping', 'User Research'],
  'ui': ['UI/UX Design', 'Figma', 'Prototyping', 'Wireframing'],
  'culinar': ['Culinary Techniques', 'Food Safety', 'Kitchen Management', 'Menu Planning'],
  'طبخ': ['Culinary Techniques', 'Food Safety', 'Kitchen Management', 'Menu Planning'],
  'cook': ['Culinary Techniques', 'Food Safety', 'Kitchen Management'],
  'fashion': ['Fashion Design', 'Sewing', 'Trend Research', 'Textile Knowledge'],
  'موضة': ['Fashion Design', 'Sewing', 'Trend Research', 'Textile Knowledge'],
  'mechanic': ['Mechanical Design', 'CAD', 'Thermodynamics', 'Problem Solving'],
  'electric': ['Circuit Design', 'Electrical Systems', 'Troubleshooting', 'CAD'],
  'كهرب': ['Circuit Design', 'Electrical Systems', 'Troubleshooting', 'CAD'],
  'civil': ['Structural Design', 'AutoCAD', 'Project Planning', 'Surveying'],
  'chem': ['Laboratory Techniques', 'Data Analysis', 'Research', 'Safety Protocols'],
  'كيمي': ['Laboratory Techniques', 'Data Analysis', 'Research', 'Safety Protocols'],
  'physics': ['Mathematics', 'Data Analysis', 'Research', 'Lab Skills'],
  'bio': ['Laboratory Techniques', 'Research', 'Data Analysis', 'Field Work'],
  'بيولوج': ['Laboratory Techniques', 'Research', 'Data Analysis', 'Field Work'],
  'vet': ['Animal Care', 'Anatomy', 'Clinical Skills', 'Communication'],
  'aviation': ['Flight Operations', 'Navigation', 'Safety Procedures', 'Discipline'],
  'طيران': ['Flight Operations', 'Navigation', 'Safety Procedures', 'Discipline'],
  'logistic': ['Supply Chain', 'Inventory Management', 'Coordination', 'Problem Solving'],
  'real estate': ['Property Valuation', 'Negotiation', 'Market Research', 'Communication'],
  'عقار': ['Property Valuation', 'Negotiation', 'Market Research', 'Communication'],
  'social media': ['Content Strategy', 'Copywriting', 'Analytics', 'Community Management'],
  'video': ['Video Editing', 'Storytelling', 'Color Grading', 'Premiere Pro'],
  'فيديو': ['Video Editing', 'Storytelling', 'Color Grading', 'Premiere Pro'],
  'animat': ['2D/3D Animation', 'Storyboarding', 'Character Design', 'After Effects'],
  'game': ['Game Design', 'Unity', 'C#', 'Level Design'],
  'translat': ['Translation', 'Bilingual Communication', 'Proofreading', 'Cultural Awareness'],
  'ترجم': ['Translation', 'Bilingual Communication', 'Proofreading', 'Cultural Awareness'],
  'teach': ['Lesson Planning', 'Public Speaking', 'Curriculum Design', 'Patience'],
  'تدريس': ['Lesson Planning', 'Public Speaking', 'Curriculum Design', 'Patience'],
  'architect': ['Architectural Design', 'AutoCAD', '3D Modeling', 'Spatial Reasoning'],
  'enviro': ['Sustainability', 'Field Work', 'Data Analysis', 'Report Writing'],
  'finance': ['Financial Analysis', 'Excel', 'Modeling', 'Attention to Detail'],
  'مال': ['Financial Analysis', 'Excel', 'Modeling', 'Attention to Detail'],
  'account': ['Accounting', 'Excel', 'Bookkeeping', 'Attention to Detail'],
  'law': ['Legal Research', 'Writing', 'Argumentation', 'Attention to Detail'],
  'قانون': ['Legal Research', 'Writing', 'Argumentation', 'Attention to Detail'],
  'psych': ['Active Listening', 'Research', 'Empathy', 'Data Analysis', 'Writing'],
  'نف': ['Active Listening', 'Research', 'Empathy', 'Data Analysis', 'Writing'],
  'marketing': ['Marketing', 'Copywriting', 'Analytics', 'Campaign Planning'],
  'تسويق': ['Marketing', 'Copywriting', 'Analytics', 'Campaign Planning'],
  'writing': ['Content Writing', 'Editing', 'Research', 'Storytelling'],
  'كتب': ['Content Writing', 'Editing', 'Research', 'Storytelling'],
  'photograph': ['Photography', 'Photo Editing', 'Composition', 'Lighting'],
  'تصوير': ['Photography', 'Photo Editing', 'Composition', 'Lighting'],
  'music': ['Music Theory', 'Performance', 'Composition', 'Collaboration'],
  'موسيق': ['Music Theory', 'Performance', 'Composition', 'Collaboration'],
  'sport': ['Coaching', 'Fitness', 'Teamwork', 'Discipline', 'Communication'],
  'رياض': ['Coaching', 'Fitness', 'Teamwork', 'Discipline', 'Communication'],
  'agricultur': ['Crop Science', 'Field Work', 'Data Analysis', 'Sustainability'],
  'زراع': ['Crop Science', 'Field Work', 'Data Analysis', 'Sustainability'],
};

/// Best-guess study field for a custom domain, used in the education entry.
const Map<String, String> _customDomainFields = {
  'robot': 'Robotics Engineering',
  'روبوت': 'Robotics Engineering',
  'nurs': 'Nursing',
  'تمريض': 'Nursing',
  'medic': 'Medicine',
  'طب': 'Medicine',
  'cyber': 'Cybersecurity',
  'أمن': 'Security Studies',
  'ai': 'Artificial Intelligence',
  'ذكاء': 'Artificial Intelligence',
  'graphic': 'Graphic Design',
  'تصميم': 'Design',
  'design': 'Design',
  'culinar': 'Culinary Arts',
  'طبخ': 'Culinary Arts',
  'fashion': 'Fashion Design',
  'موضة': 'Fashion Design',
  'mechanic': 'Mechanical Engineering',
  'electric': 'Electrical Engineering',
  'كهرب': 'Electrical Engineering',
  'civil': 'Civil Engineering',
  'chem': 'Chemistry',
  'كيمي': 'Chemistry',
  'physics': 'Physics',
  'bio': 'Biology',
  'بيولوج': 'Biology',
  'vet': 'Veterinary Medicine',
  'aviation': 'Aviation',
  'طيران': 'Aviation',
  'logistic': 'Logistics',
  'real estate': 'Real Estate',
  'عقار': 'Real Estate',
  'social media': 'Media Studies',
  'video': 'Film & Media',
  'فيديو': 'Film & Media',
  'animat': 'Animation',
  'game': 'Game Development',
  'translat': 'Translation',
  'ترجم': 'Translation',
  'teach': 'Education',
  'تدريس': 'Education',
  'architect': 'Architecture',
  'enviro': 'Environmental Science',
  'finance': 'Finance',
  'مال': 'Finance',
  'account': 'Accounting',
  'law': 'Law',
  'قانون': 'Law',
  'psych': 'Psychology',
  'نف': 'Psychology',
  'marketing': 'Marketing',
  'تسويق': 'Marketing',
  'writing': 'Communications',
  'كتب': 'Communications',
  'photograph': 'Photography',
  'تصوير': 'Photography',
  'music': 'Music',
  'موسيق': 'Music',
  'sport': 'Sports Science',
  'رياض': 'Sports Science',
  'agricultur': 'Agriculture',
  'زراع': 'Agriculture',
};

String _customDomainField(String lower, String title) {
  for (final entry in _customDomainFields.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return title;
}

_Blueprint _blueprintForCustom(String name) {
  final title = _titleCase(name);
  final lower = name.toLowerCase();
  final skills = <String>{title};
  for (final entry in _customDomainSkills.entries) {
    if (lower.contains(entry.key)) skills.addAll(entry.value);
  }
  if (skills.length <= 1) {
    // Unrecognised domain — keep an honest, useful generic set.
    skills.addAll(['Communication', 'Problem Solving', 'Teamwork', 'Time Management']);
  }
  final field = _customDomainField(lower, title);
  return _Blueprint(
    role: 'aspiring $title professional',
    skills: skills.toList(),
    experience: ProfileExperience(role: '$title Trainee', company: 'University Club', years: 0),
    project: ProfileProject(
      name: '$title Project',
      description: 'Started a hands-on project in $title.',
      tech: const [],
    ),
    education: ProfileEducation(degree: 'Bachelor’s', field: field),
    certification: '$title Fundamentals',
    achievement: 'Took initiative to grow in $title',
  );
}

_Blueprint _blueprint(Interest interest) => switch (interest) {
      Interest.programming => const _Blueprint(
          role: 'aspiring Flutter developer',
          skills: ['Flutter', 'Dart', 'REST APIs', 'Git', 'UI Implementation', 'Problem Solving'],
          experience: ProfileExperience(role: 'Flutter Developer (Trainee)', company: 'University Tech Club', years: 0),
          project: ProfileProject(
            name: 'Habit Tracker App',
            description: 'Cross-platform app built with Flutter and a local database.',
            tech: ['Flutter', 'Dart'],
          ),
          education: ProfileEducation(degree: 'B.Sc.', field: 'Computer Science'),
          certification: 'Flutter Development (in progress)',
          achievement: 'Built and published a Flutter app from scratch',
        ),
      Interest.design => const _Blueprint(
          role: 'aspiring UI/UX designer',
          skills: ['UI/UX Design', 'Figma', 'Wireframing', 'Prototyping', 'Design Systems', 'User Research'],
          experience: ProfileExperience(role: 'UI/UX Design Trainee', company: 'Design Sprint Bootcamp', years: 0),
          project: ProfileProject(
            name: 'Mobile App Redesign',
            description: 'Figma prototype that simplifies the onboarding flow.',
            tech: ['Figma'],
          ),
          education: ProfileEducation(degree: 'B.A.', field: 'Graphic / UI Design'),
          certification: 'Google UX Design',
          achievement: 'Redesigned a flow that cut steps by 40%',
        ),
      Interest.writing => const _Blueprint(
          role: 'emerging content writer',
          skills: ['Content Writing', 'Copywriting', 'Editing', 'SEO Basics', 'Storytelling'],
          experience: ProfileExperience(role: 'Content Writer', company: 'Campus Magazine', years: 0),
          project: ProfileProject(
            name: 'Tech Blog Series',
            description: 'Published articles on student tech trends.',
            tech: [],
          ),
          education: ProfileEducation(degree: 'B.A.', field: 'Mass Communication'),
          certification: 'Copywriting Essentials',
          achievement: 'Grew a blog readership past 1,000 readers',
        ),
      Interest.data => const _Blueprint(
          role: 'aspiring data analyst',
          skills: ['Data Analysis', 'SQL', 'Python', 'Excel', 'Data Visualization', 'Statistics'],
          experience: ProfileExperience(role: 'Data Analysis Trainee', company: 'Open Data Initiative', years: 0),
          project: ProfileProject(
            name: 'Public Dataset Dashboard',
            description: 'Analyzed open data and visualized the key trends.',
            tech: ['Python', 'Excel'],
          ),
          education: ProfileEducation(degree: 'B.Sc.', field: 'Statistics / Data Science'),
          certification: 'Data Analytics Fundamentals',
          achievement: 'Uncovered insights adopted by a student team',
        ),
      Interest.marketing => const _Blueprint(
          role: 'marketing enthusiast',
          skills: ['Social Media', 'Campaigns', 'Content Strategy', 'Analytics', 'Branding'],
          experience: ProfileExperience(role: 'Marketing Assistant', company: 'Student Society', years: 0),
          project: ProfileProject(
            name: 'Club Social Campaign',
            description: 'Ran a semester-long Instagram campaign.',
            tech: [],
          ),
          education: ProfileEducation(degree: 'B.A.', field: 'Marketing'),
          certification: 'Digital Marketing Basics',
          achievement: 'Ran a campaign with 20%+ engagement',
        ),
      Interest.teaching => const _Blueprint(
          role: 'peer tutor',
          skills: ['Tutoring', 'Public Speaking', 'Lesson Planning', 'Communication'],
          experience: ProfileExperience(role: 'Peer Tutor', company: 'University Tutoring Center', years: 0),
          project: ProfileProject(
            name: 'Study Group Toolkit',
            description: 'Created revision guides used by 50+ students.',
            tech: [],
          ),
          education: ProfileEducation(degree: 'B.A.', field: 'Education'),
          certification: 'Peer Tutoring Certificate',
          achievement: 'Helped peers raise grades by a full letter',
        ),
      Interest.business => const _Blueprint(
          role: 'business student',
          skills: ['Project Management', 'Research', 'Excel', 'Communication'],
          experience: ProfileExperience(role: 'Project Coordinator (Volunteer)', company: 'Business Club', years: 0),
          project: ProfileProject(
            name: 'Case Competition Prep',
            description: 'Built a market-entry plan for a student case competition.',
            tech: ['Excel'],
          ),
          education: ProfileEducation(degree: 'B.Sc.', field: 'Business Administration'),
          certification: 'Project Management Basics',
          achievement: 'Led a team in a national case competition',
        ),
      Interest.engineering => const _Blueprint(
          role: 'aspiring engineer',
          skills: ['Engineering Design', 'Problem Solving', 'Math', 'CAD Basics', 'Teamwork'],
          experience: ProfileExperience(role: 'Engineering Trainee', company: 'University Engineering Club', years: 0),
          project: ProfileProject(
            name: 'Prototype Build',
            description: 'Built a working prototype for a class project.',
            tech: [],
          ),
          education: ProfileEducation(degree: 'B.Sc.', field: 'Engineering'),
          certification: 'Engineering Fundamentals',
          achievement: 'Built a prototype that solved a real problem',
        ),
      Interest.medicine => const _Blueprint(
          role: 'aspiring healthcare professional',
          skills: ['Anatomy Basics', 'Patient Care', 'Communication', 'Research', 'Teamwork'],
          experience: ProfileExperience(role: 'Clinical Observer', company: 'Local Hospital', years: 0),
          project: ProfileProject(
            name: 'Health Awareness Campaign',
            description: 'Organized a campus health awareness event.',
            tech: [],
          ),
          education: ProfileEducation(degree: 'B.Sc.', field: 'Medicine / Health Sciences'),
          certification: 'First Aid Certified',
          achievement: 'Contributed to a community health initiative',
        ),
      Interest.law => const _Blueprint(
          role: 'aspiring legal professional',
          skills: ['Legal Research', 'Writing', 'Argumentation', 'Critical Thinking', 'Communication'],
          experience: ProfileExperience(role: 'Legal Intern', company: 'Law Office', years: 0),
          project: ProfileProject(
            name: 'Case Brief Series',
            description: 'Wrote briefs analyzing real cases.',
            tech: [],
          ),
          education: ProfileEducation(degree: 'LL.B.', field: 'Law'),
          certification: 'Legal Writing Certificate',
          achievement: 'Won a moot court round',
        ),
      Interest.finance => const _Blueprint(
          role: 'aspiring finance professional',
          skills: ['Financial Analysis', 'Excel', 'Accounting', 'Modeling', 'Attention to Detail'],
          experience: ProfileExperience(role: 'Finance Trainee', company: 'Student Finance Society', years: 0),
          project: ProfileProject(
            name: 'Budget Planner',
            description: 'Built a personal finance model in Excel.',
            tech: ['Excel'],
          ),
          education: ProfileEducation(degree: 'B.Com.', field: 'Finance / Accounting'),
          certification: 'Financial Modeling Basics',
          achievement: 'Managed a club budget of five-figure scale',
        ),
      Interest.psychology => const _Blueprint(
          role: 'aspiring psychologist',
          skills: ['Active Listening', 'Research', 'Empathy', 'Data Analysis', 'Writing'],
          experience: ProfileExperience(role: 'Research Assistant', company: 'Psychology Lab', years: 0),
          project: ProfileProject(
            name: 'Behavior Study',
            description: 'Assisted a study on student behavior.',
            tech: [],
          ),
          education: ProfileEducation(degree: 'B.A.', field: 'Psychology'),
          certification: 'Mental Health First Aid',
          achievement: 'Co-authored a student research poster',
        ),
      Interest.photography => const _Blueprint(
          role: 'aspiring photographer',
          skills: ['Photography', 'Photo Editing', 'Composition', 'Lighting', 'Storytelling'],
          experience: ProfileExperience(role: 'Photographer', company: 'Campus Media', years: 0),
          project: ProfileProject(
            name: 'Photo Series',
            description: 'Shot a series on campus life.',
            tech: [],
          ),
          education: ProfileEducation(degree: 'B.A.', field: 'Visual Arts'),
          certification: 'Digital Photography Basics',
          achievement: 'Had work featured in a student exhibition',
        ),
      Interest.music => const _Blueprint(
          role: 'aspiring musician',
          skills: ['Music Theory', 'Performance', 'Composition', 'Collaboration', 'Creativity'],
          experience: ProfileExperience(role: 'Band Member', company: 'University Music Society', years: 0),
          project: ProfileProject(
            name: 'Original Track',
            description: 'Produced an original song.',
            tech: [],
          ),
          education: ProfileEducation(degree: 'B.A.', field: 'Music'),
          certification: 'Music Production Basics',
          achievement: 'Performed at a campus event',
        ),
      Interest.sports => const _Blueprint(
          role: 'aspiring sports professional',
          skills: ['Coaching', 'Fitness', 'Teamwork', 'Discipline', 'Communication'],
          experience: ProfileExperience(role: 'Team Captain', company: 'University Team', years: 0),
          project: ProfileProject(
            name: 'Training Plan',
            description: 'Designed a training plan for teammates.',
            tech: [],
          ),
          education: ProfileEducation(degree: 'B.Sc.', field: 'Sports Science'),
          certification: 'Sports Coaching Certificate',
          achievement: 'Led a team to a tournament finish',
        ),
      Interest.hospitality => const _Blueprint(
          role: 'hospitality enthusiast',
          skills: ['Customer Service', 'Event Planning', 'Communication', 'Organization', 'Languages'],
          experience: ProfileExperience(role: 'Front Desk Assistant', company: 'Hotel Internship', years: 0),
          project: ProfileProject(
            name: 'Event Setup',
            description: 'Helped organize a hospitality event.',
            tech: [],
          ),
          education: ProfileEducation(degree: 'B.A.', field: 'Hospitality Management'),
          certification: 'Hospitality Service Certificate',
          achievement: 'Earned high guest satisfaction ratings',
        ),
      Interest.agriculture => const _Blueprint(
          role: 'aspiring agronomist',
          skills: ['Crop Science', 'Field Work', 'Data Analysis', 'Sustainability', 'Problem Solving'],
          experience: ProfileExperience(role: 'Farm Intern', company: 'Agricultural Co-op', years: 0),
          project: ProfileProject(
            name: 'Yield Study',
            description: 'Tracked crop yields for a small plot.',
            tech: [],
          ),
          education: ProfileEducation(degree: 'B.Sc.', field: 'Agriculture'),
          certification: 'Sustainable Farming Basics',
          achievement: 'Improved a plot’s yield through a small experiment',
        ),
      Interest.science => const _Blueprint(
          role: 'aspiring researcher',
          skills: ['Lab Skills', 'Data Analysis', 'Research', 'Writing', 'Critical Thinking'],
          experience: ProfileExperience(role: 'Lab Assistant', company: 'University Lab', years: 0),
          project: ProfileProject(
            name: 'Lab Report Series',
            description: 'Documented experiments with clear analysis.',
            tech: [],
          ),
          education: ProfileEducation(degree: 'B.Sc.', field: 'Science'),
          certification: 'Laboratory Safety Certified',
          achievement: 'Presented findings at a student symposium',
        ),
      Interest.sales => const _Blueprint(
          role: 'aspiring sales professional',
          skills: ['Communication', 'Negotiation', 'Relationship Building', 'Persistence', 'Product Knowledge'],
          experience: ProfileExperience(role: 'Sales Intern', company: 'Retail Store', years: 0),
          project: ProfileProject(
            name: 'Promo Campaign',
            description: 'Ran a weekend promotion that lifted sales.',
            tech: [],
          ),
          education: ProfileEducation(degree: 'B.A.', field: 'Business'),
          certification: 'Sales Fundamentals',
          achievement: 'Exceeded a monthly sales target',
        ),
    };
