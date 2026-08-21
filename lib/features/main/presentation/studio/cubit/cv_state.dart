import 'package:equatable/equatable.dart';

import '../../../../../domain/cv/cv_content_validator.dart';
import '../../../../../domain/entities/career_dna.dart';
import '../../../../../domain/entities/career_target.dart';
import '../../../../../domain/entities/cv_content.dart';
import '../../../../../domain/entities/cv_document.dart';
import '../../../../../domain/entities/job_analysis.dart';

enum CvStatus {
  initial,
  loading,
  generating,
  ready,
  saving,
  failure,
  deleted,
}

class CvState extends Equatable {
  const CvState({
    this.status = CvStatus.initial,
    this.documents = const [],
    this.targets = const [],
    this.analyses = const [],
    this.dna,
    this.selectedDocument,
    this.content,
    this.templateId = 'nexoraMinimal',
    this.isAiGenerated = false,
    this.targetId,
    this.analysisId,
    this.versions = const [],
    this.message,
    this.validationIssues = const [],
  });

  final CvStatus status;
  final List<CvDocument> documents;
  final List<CareerTarget> targets;
  final List<JobAnalysis> analyses;
  final CareerDna? dna;
  final CvDocument? selectedDocument;
  final CvContent? content;
  final String templateId;
  final bool isAiGenerated;
  final String? targetId;
  final String? analysisId;
  final List<CvVersion> versions;
  final String? message;
  final List<CvValidationIssue> validationIssues;

  CvState copyWith({
    CvStatus? status,
    List<CvDocument>? documents,
    List<CareerTarget>? targets,
    List<JobAnalysis>? analyses,
    CareerDna? dna,
    bool clearDna = false,
    CvDocument? selectedDocument,
    bool clearSelectedDocument = false,
    CvContent? content,
    String? templateId,
    bool? isAiGenerated,
    String? targetId,
    bool clearTargetId = false,
    String? analysisId,
    bool clearAnalysisId = false,
    List<CvVersion>? versions,
    String? message,
    bool clearMessage = false,
    List<CvValidationIssue>? validationIssues,
  }) =>
      CvState(
        status: status ?? this.status,
        documents: documents ?? this.documents,
        targets: targets ?? this.targets,
        analyses: analyses ?? this.analyses,
        dna: clearDna ? null : (dna ?? this.dna),
        selectedDocument: clearSelectedDocument
            ? null
            : (selectedDocument ?? this.selectedDocument),
        content: content ?? this.content,
        templateId: templateId ?? this.templateId,
        isAiGenerated: isAiGenerated ?? this.isAiGenerated,
        targetId: clearTargetId ? null : (targetId ?? this.targetId),
        analysisId: clearAnalysisId ? null : (analysisId ?? this.analysisId),
        versions: versions ?? this.versions,
        message: clearMessage ? null : (message ?? this.message),
        validationIssues: validationIssues ?? this.validationIssues,
      );

  bool get isEmpty => documents.isEmpty;
  bool get hasContent => content != null;
  CvDocument? get selectedTargetDocument => selectedDocument;

  @override
  List<Object?> get props => [
        status,
        documents,
        targets,
        analyses,
        dna,
        selectedDocument,
        content,
        templateId,
        isAiGenerated,
        targetId,
        analysisId,
        versions,
        message,
        validationIssues,
      ];
}
