/// A user-added Career DNA section (Volunteering / Publications / Courses).
///
/// The base DNA sections are product content and are never persisted; only
/// sections the user adds end up in storage.
class ProfileSection {
  const ProfileSection({
    required this.id,
    required this.label,
    required this.pct,
    this.category = 'v',
  });

  final String id;
  final String label;
  final double pct;

  /// Persistence code: 'v' (Volunteering) | 'p' (Publications) | 'c' (Courses).
  final String category;

  ProfileSection copyWith({double? pct}) => ProfileSection(
        id: id,
        label: label,
        pct: pct ?? this.pct,
        category: category,
      );

  Map<String, Object> toJson() => {
        'id': id,
        'label': label,
        'pct': pct,
        'category': category,
      };

  factory ProfileSection.fromJson(Map<String, dynamic> json) => ProfileSection(
        id: json['id'] as String? ?? '',
        label: json['label'] as String,
        pct: (json['pct'] as num?)?.toDouble() ?? 0,
        category: json['category'] as String? ?? 'v',
      );
}
