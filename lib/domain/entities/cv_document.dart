import 'package:equatable/equatable.dart';

import 'cv_content.dart';

/// Metadata for a CV belonging to a [CareerTarget].
///
/// Does NOT contain the actual CV content — that lives in [CvVersion]s.
class CvDocument extends Equatable {
  const CvDocument({
    required this.id,
    required this.userId,
    required this.targetId,
    required this.templateId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.analysisId,
  });

  final String id;
  final String userId;
  final String targetId;
  final String templateId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? analysisId;

  CvDocument copyWith({
    String? id,
    String? userId,
    String? targetId,
    String? templateId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? analysisId,
  }) =>
      CvDocument(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        targetId: targetId ?? this.targetId,
        templateId: templateId ?? this.templateId,
        title: title ?? this.title,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        analysisId: analysisId ?? this.analysisId,
      );

  Map<String, Object> toJson() => {
        'id': id,
        'user_id': userId,
        'target_id': targetId,
        'template_id': templateId,
        'title': title,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
        // ignore: use_null_aware_elements
        if (analysisId != null) 'analysis_id': analysisId!,
      };

  factory CvDocument.fromJson(Map<String, dynamic> json) => CvDocument(
        id: json['id'] as String,
        userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
        targetId: json['target_id'] as String? ?? json['targetId'] as String? ?? '',
        templateId: json['template_id'] as String? ?? json['templateId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        createdAt: json['created_at'] is String
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.fromMillisecondsSinceEpoch(
                (json['created_at'] as num?)?.toInt() ?? 0),
        updatedAt: json['updated_at'] is String
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.fromMillisecondsSinceEpoch(
                (json['updated_at'] as num?)?.toInt() ?? 0),
        analysisId: json['analysis_id'] as String? ?? json['analysisId'] as String?,
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        targetId,
        templateId,
        title,
        createdAt,
        updatedAt,
        analysisId,
      ];
}

/// A single immutable version of a CV's structured content.
class CvVersion extends Equatable {
  const CvVersion({
    required this.id,
    required this.documentId,
    required this.userId,
    required this.version,
    required this.content,
    required this.templateId,
    required this.createdAt,
    required this.updatedAt,
    this.evaluationId,
  });

  final String id;
  final String documentId;
  final String userId;
  final int version;
  final CvContent content;
  final String templateId;

  /// Reserved for Phase 2E evaluation linkage. Not used in Phase 2D.
  final String? evaluationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  CvVersion copyWith({
    String? id,
    String? documentId,
    String? userId,
    int? version,
    CvContent? content,
    String? templateId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? evaluationId,
  }) =>
      CvVersion(
        id: id ?? this.id,
        documentId: documentId ?? this.documentId,
        userId: userId ?? this.userId,
        version: version ?? this.version,
        content: content ?? this.content,
        templateId: templateId ?? this.templateId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        evaluationId: evaluationId ?? this.evaluationId,
      );

  Map<String, Object> toJson() => {
        'id': id,
        'document_id': documentId,
        'user_id': userId,
        'version': version,
        'content': content.toJson(),
        'template_id': templateId,
        // ignore: use_null_aware_elements
        if (evaluationId != null) 'evaluation_id': evaluationId!,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory CvVersion.fromJson(Map<String, dynamic> json) => CvVersion(
        id: json['id'] as String,
        documentId: json['document_id'] as String? ?? json['documentId'] as String? ?? '',
        userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
        version: (json['version'] as num?)?.toInt() ?? 1,
        content: json['content'] is Map
            ? CvContent.fromJson(Map<String, dynamic>.from(json['content']))
            : const CvContent(),
        templateId: json['template_id'] as String? ?? json['templateId'] as String? ?? '',
        evaluationId: json['evaluation_id'] as String? ?? json['evaluationId'] as String?,
        createdAt: json['created_at'] is String
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.fromMillisecondsSinceEpoch(
                (json['created_at'] as num?)?.toInt() ?? 0),
        updatedAt: json['updated_at'] is String
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.fromMillisecondsSinceEpoch(
                (json['updated_at'] as num?)?.toInt() ?? 0),
      );

  @override
  List<Object?> get props => [
        id,
        documentId,
        userId,
        version,
        content,
        templateId,
        evaluationId,
        createdAt,
        updatedAt,
      ];
}
