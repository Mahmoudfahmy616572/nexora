/// A CV version managed on the Studio tab.
class CvProfile {
  const CvProfile({
    required this.id,
    required this.title,
    required this.ats,
    required this.purpose,
    required this.updated,
    required this.match,
    this.best = false,
  });

  final String id;
  final String title;
  final int ats;
  final String purpose;
  final String updated;
  final int match;
  final bool best;

  CvProfile copyWith({String? title, int? ats, int? match}) => CvProfile(
        id: id,
        title: title ?? this.title,
        ats: ats ?? this.ats,
        purpose: purpose,
        updated: updated,
        match: match ?? this.match,
        best: best,
      );

  Map<String, Object> toJson() => {
        'id': id,
        'title': title,
        'ats': ats,
        'purpose': purpose,
        'updated': updated,
        'match': match,
        'best': best,
      };

  factory CvProfile.fromJson(Map<String, dynamic> json) => CvProfile(
        id: json['id'] as String,
        title: json['title'] as String,
        ats: (json['ats'] as num).toInt(),
        purpose: json['purpose'] as String,
        updated: json['updated'] as String,
        match: (json['match'] as num).toInt(),
        best: json['best'] as bool? ?? false,
      );
}
