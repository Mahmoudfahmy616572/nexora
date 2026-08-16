/// A job application tracked on the Tracker tab.
class JobApplication {
  const JobApplication({
    required this.id,
    required this.company,
    required this.role,
    required this.status,
    required this.date,
    required this.match,
    required this.ats,
  });

  final String id;
  final String company;
  final String role;
  final String status;
  final String date;
  final int match;
  final int ats;

  /// Whether the application is still in the running (not an offer / rejected).
  bool get active => !(status.startsWith('Offer') || status == 'Rejected');

  JobApplication copyWith({String? status, String? date}) => JobApplication(
        id: id,
        company: company,
        role: role,
        status: status ?? this.status,
        date: date ?? this.date,
        match: match,
        ats: ats,
      );

  Map<String, Object> toJson() => {
        'id': id,
        'company': company,
        'role': role,
        'status': status,
        'date': date,
        'match': match,
        'ats': ats,
      };

  factory JobApplication.fromJson(Map<String, dynamic> json) => JobApplication(
        id: json['id'] as String,
        company: json['company'] as String,
        role: json['role'] as String,
        status: json['status'] as String,
        date: json['date'] as String,
        match: (json['match'] as num).toInt(),
        ats: (json['ats'] as num).toInt(),
      );
}
