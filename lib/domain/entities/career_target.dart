import 'dart:math';

/// The kind of opportunity a user is targeting. Extensible: new types only need
/// a name mapping and (optionally) UI handling.
enum TargetType {
  job,
  internship,
  graduateProgram,
  academicApplication,
  custom,
}

const Map<TargetType, String> _targetTypeNames = {
  TargetType.job: 'job',
  TargetType.internship: 'internship',
  TargetType.graduateProgram: 'graduateProgram',
  TargetType.academicApplication: 'academicApplication',
  TargetType.custom: 'custom',
};

TargetType _parseTargetType(dynamic value) {
  if (value is String) {
    for (final entry in _targetTypeNames.entries) {
      if (entry.value == value) return entry.key;
    }
  }
  return TargetType.custom;
}

/// A specific opportunity a user is preparing for — a job, internship, graduate
/// program, academic application, or a custom target. Career Intelligence uses
/// these to focus its guidance.
class CareerTarget {
  /// Generates a valid RFC-4122 v4 UUID without an external dependency. Supabase
  /// uses a `uuid` primary key, so ids must be well-formed.
  static String newId() {
    final rng = Random();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).toList();
    return '${hex.sublist(0, 4).join()}-${hex.sublist(4, 6).join()}-'
        '${hex.sublist(6, 8).join()}-${hex.sublist(8, 10).join()}-'
        '${hex.sublist(10, 16).join()}';
  }

  const CareerTarget({
    required this.id,
    required this.userId,
    required this.type,
    required this.role,
    this.industry,
    this.countryRegion,
    this.seniority,
    this.language,
    this.jobDescription,
    this.company,
    this.url,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final TargetType type;
  final String role;
  final String? industry;
  final String? countryRegion;
  final String? seniority;
  final String? language;
  final String? jobDescription;
  final String? company;
  final String? url;
  final DateTime createdAt;
  final DateTime updatedAt;

  CareerTarget copyWith({
    String? id,
    String? userId,
    TargetType? type,
    String? role,
    String? industry,
    String? countryRegion,
    String? seniority,
    String? language,
    String? jobDescription,
    String? company,
    String? url,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      CareerTarget(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        type: type ?? this.type,
        role: role ?? this.role,
        industry: industry ?? this.industry,
        countryRegion: countryRegion ?? this.countryRegion,
        seniority: seniority ?? this.seniority,
        language: language ?? this.language,
        jobDescription: jobDescription ?? this.jobDescription,
        company: company ?? this.company,
        url: url ?? this.url,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object> toJson() {
    final map = <String, Object>{
      'id': id,
      'user_id': userId,
      'type': _targetTypeNames[type]!,
      'role': role,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
    if (industry != null) map['industry'] = industry!;
    if (countryRegion != null) map['country_region'] = countryRegion!;
    if (seniority != null) map['seniority'] = seniority!;
    if (language != null) map['language'] = language!;
    if (jobDescription != null) map['job_description'] = jobDescription!;
    if (company != null) map['company'] = company!;
    if (url != null) map['url'] = url!;
    return map;
  }

  factory CareerTarget.fromJson(Map<String, dynamic> json) => CareerTarget(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        type: _parseTargetType(json['type']),
        role: json['role'] as String,
        industry: json['industry'] as String?,
        countryRegion: json['country_region'] as String?,
        seniority: json['seniority'] as String?,
        language: json['language'] as String?,
        jobDescription: json['job_description'] as String?,
        company: json['company'] as String?,
        url: json['url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
