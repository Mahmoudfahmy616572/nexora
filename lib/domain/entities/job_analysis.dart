/// A completed opportunity analysis on the Analyze tab.
class JobAnalysis {
  const JobAnalysis({
    required this.id,
    required this.title,
    required this.company,
    required this.timeAgo,
    required this.overall,
    required this.skills,
    required this.experience,
    required this.education,
    required this.keywords,
    required this.strong,
    required this.missing,
    this.aiRecommendation = '',
  });

  final String id;
  final String title;
  final String company;
  final String timeAgo;
  final double overall;
  final double skills;
  final double experience;
  final double education;
  final double keywords;
  final List<String> strong;
  final List<String> missing;

  /// AI-generated, candidate-specific advice from the analyze edge function.
  final String aiRecommendation;

  /// Serialized with the database column name `time_ago`.
  Map<String, Object> toJson() => {
        'id': id,
        'title': title,
        'company': company,
        'time_ago': timeAgo,
        'overall': overall,
        'skills': skills,
        'experience': experience,
        'education': education,
        'keywords': keywords,
        'strong': strong,
        'missing': missing,
        'ai_recommendation': aiRecommendation,
      };

  factory JobAnalysis.fromJson(Map<String, dynamic> json) => JobAnalysis(
        id: json['id'] as String,
        title: json['title'] as String,
        company: json['company'] as String,
        timeAgo: (json['time_ago'] ?? json['timeAgo']) as String,
        overall: (json['overall'] as num).toDouble(),
        skills: (json['skills'] as num).toDouble(),
        experience: (json['experience'] as num).toDouble(),
        education: (json['education'] as num).toDouble(),
        keywords: (json['keywords'] as num).toDouble(),
        strong: [for (final s in json['strong'] as List) s as String],
        missing: [for (final s in json['missing'] as List) s as String],
        aiRecommendation:
            (json['ai_recommendation'] ?? json['aiRecommendation']) as String? ?? '',
      );
}
