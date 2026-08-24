import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/cv/cv_content_validator.dart';
import '../../../../../domain/cv/cv_factual_builder.dart';
import '../../../../../domain/entities/career_dna.dart';
import '../../../../../domain/entities/career_target.dart';
import '../../../../../domain/entities/cv_content.dart';
import '../../../../../domain/entities/cv_document.dart';
import '../../../../../domain/entities/job_analysis.dart';
import '../../../../../domain/repositories/career_dna_repository.dart';
import '../../../../../domain/repositories/career_target_repository.dart';
import '../../../../../domain/repositories/cv_document_repository.dart';
import '../../../../../domain/repositories/cv_generation_repository.dart';
import '../../../../../domain/repositories/job_analysis_repository.dart';

import 'cv_state.dart';

/// Manages the CV Engine: documents, generation, factual fallback, versioning,
/// template switching, and deletion.
class CvCubit extends Cubit<CvState> {
  CvCubit(
    this._docRepo,
    this._genRepo,
    this._dnaRepo,
    this._targetRepo,
    this._analysisRepo,
  ) : super(const CvState());

  final CvDocumentRepository _docRepo;
  final CvGenerationRepository _genRepo;
  final CareerDnaRepository _dnaRepo;
  final CareerTargetRepository _targetRepo;
  final JobAnalysisRepository _analysisRepo;

  static String _newId() => CareerTarget.newId();

  T? _first<T>(List<T> list, bool Function(T) test) =>
      list.where(test).firstOrNull;

  Future<CareerDna> _ensureDna(CareerDna? cached) async =>
      cached ?? (await _dnaRepo.load()) ?? CareerDna();

  /// Emits only when the cubit is still open. Guards async methods that may
  /// complete after the cubit was closed (e.g. during navigation), which would
  /// otherwise throw `Bad state: Cannot emit new states after calling close`.
  void _safeEmit(CvState next) {
    if (!isClosed) emit(next);
  }

  Future<void> load() async {
    _safeEmit(state.copyWith(status: CvStatus.loading, clearMessage: true));
    try {
      final results = await Future.wait([
        _docRepo.loadDocuments(),
        _targetRepo.loadAll(),
        _analysisRepo.load(),
      ]);
      final dna = await _dnaRepo.load();
      final documents = results[0] as List<CvDocument>;
      final targets = results[1] as List<CareerTarget>;
      final analyses = results[2] as List<JobAnalysis>? ?? const [];
      _safeEmit(state.copyWith(
        status: documents.isEmpty ? CvStatus.initial : CvStatus.ready,
        documents: documents,
        targets: targets,
        analyses: analyses,
        dna: dna,
      ));
    } on Object {
      _safeEmit(state.copyWith(
        status: CvStatus.failure,
        message: 'Could not load your CVs. Please try again.',
      ));
    }
  }

  void selectTarget(String? id) =>
      _safeEmit(state.copyWith(targetId: id, clearTargetId: id == null));

  void setAnalysisId(String? id) =>
      _safeEmit(state.copyWith(analysisId: id, clearAnalysisId: id == null));

  /// Returns from the editor to the CV list without creating a version.
  void backToList() => _safeEmit(state.copyWith(
        clearSelectedDocument: true,
        content: null,
        targetId: null,
        analysisId: null,
        versions: const [],
        clearMessage: true,
      ));

  /// Begins a new CV: records the intent (target/analysis) and generates.
  Future<void> startCreation({
    required String title,
    required String templateId,
    String? targetId,
    String? analysisId,
  }) async {
    final now = DateTime.now();
    final doc = CvDocument(
      id: _newId(),
      userId: '',
      targetId: targetId ?? '',
      templateId: templateId,
      title: title,
      createdAt: now,
      updatedAt: now,
      analysisId: analysisId,
    );
    _safeEmit(state.copyWith(
      status: CvStatus.generating,
      selectedDocument: doc,
      templateId: templateId,
      targetId: targetId,
      analysisId: analysisId,
      clearMessage: true,
    ));
    await _generate();
  }

  Future<void> _generate() async {
    final dna = await _ensureDna(state.dna);
    final target = _first(state.targets, (t) => t.id == state.targetId);
    if (target == null) {
      _safeEmit(state.copyWith(
        status: CvStatus.failure,
        message: 'A target is required to generate a CV.',
      ));
      return;
    }
    final analysis = state.analysisId == null
        ? null
        : _first(state.analyses, (a) => a.id == state.analysisId);
    _safeEmit(state.copyWith(status: CvStatus.generating, clearMessage: true, dna: dna));
    try {
      final content = await _genRepo.generate(
        dna: dna,
        target: target,
        analysis: analysis,
        templateId: state.templateId,
        language: 'en',
      );
      final result = CvContentValidator.validate(content, dna);
      if (!result.valid) {
        _safeEmit(state.copyWith(
          status: CvStatus.failure,
          content: content,
          isAiGenerated: true,
          validationIssues: result.issues,
          message: 'AI generation could not be safely verified. '
              'Use your Factual CV instead.',
        ));
        return;
      }
      _safeEmit(state.copyWith(
        status: CvStatus.ready,
        content: content,
        isAiGenerated: true,
        validationIssues: const [],
      ));
    } on Object {
      _safeEmit(state.copyWith(
        status: CvStatus.failure,
        message: 'AI generation is unavailable. You can still use your '
            'Factual CV — built only from verified facts.',
      ));
    }
  }

  /// Regenerates after a failure.
  Future<void> retry() => _generate();

  /// Builds the deterministic, clearly-labelled Factual CV.
  Future<void> useFactual() async {
    final dna = await _ensureDna(state.dna);
    final target = _first(state.targets, (t) => t.id == state.targetId);
    final content = CvFactualBuilder.build(dna, target: target);
    _safeEmit(state.copyWith(
      status: CvStatus.ready,
      content: content,
      isAiGenerated: false,
      validationIssues: const [],
      clearMessage: true,
    ));
  }

  /// Applies manual edits to the current content. Edits are authoritative for
  /// the CV version and MUST NOT mutate CareerDna.
  void editContent(CvContent updated) =>
      _safeEmit(state.copyWith(content: updated, clearMessage: true));

  /// Switches the active template without changing factual content.
  void switchTemplate(String templateId) =>
      _safeEmit(state.copyWith(templateId: templateId, clearMessage: true));

  /// Persists the current content as a new version (creating the document the
  /// first time). Loading/viewing never creates a version.
  Future<void> save() async {
    if (state.content == null) return;
    _safeEmit(state.copyWith(status: CvStatus.saving, clearMessage: true));
    try {
      final dna = await _ensureDna(state.dna);
      final now = DateTime.now();
      final target =
          _first(state.targets, (t) => t.id == state.targetId) ??
          _first(state.targets, (t) => t.id == state.selectedDocument?.targetId);
      final doc = state.selectedDocument ??
          CvDocument(
            id: _newId(),
            userId: '',
            targetId: state.targetId ?? target?.id ?? '',
            templateId: state.templateId,
            title: target?.role.isNotEmpty == true
                ? '${target!.role} CV'
                : 'My CV',
            createdAt: now,
            updatedAt: now,
            analysisId: state.analysisId,
          );
      final version = CvVersion(
        id: _newId(),
        documentId: doc.id,
        userId: doc.userId,
        version: 0,
        content: state.content!,
        templateId: state.templateId,
        createdAt: now,
        updatedAt: now,
      );
      final savedDoc = await _docRepo.createDocument(doc);
      final savedVersion = await _docRepo.createVersion(
        version.copyWith(documentId: savedDoc.id, userId: savedDoc.userId),
      );
      final versions = await _docRepo.loadVersions(savedDoc.id);
      _safeEmit(state.copyWith(
        status: CvStatus.ready,
        selectedDocument: savedDoc,
        dna: dna,
        versions: versions,
        message: 'Saved as version ${savedVersion.version}.',
      ));
    } on Object {
      _safeEmit(state.copyWith(
        status: CvStatus.failure,
        message: 'Could not save the CV. Please try again.',
      ));
    }
  }

  /// Opens an existing document and loads its latest version for preview/edit.
  Future<void> openDocument(String documentId) async {
    _safeEmit(state.copyWith(status: CvStatus.loading, clearMessage: true));
    try {
      final doc = await _docRepo.loadDocument(documentId);
      final version = await _docRepo.loadLatestVersion(documentId);
      if (doc == null || version == null) {
        _safeEmit(state.copyWith(
          status: CvStatus.failure,
          message: 'This CV could not be found.',
        ));
        return;
      }
      _safeEmit(state.copyWith(
        status: CvStatus.ready,
        selectedDocument: doc,
        content: version.content,
        templateId: version.templateId,
        targetId: doc.targetId,
        analysisId: doc.analysisId,
        versions: await _docRepo.loadVersions(documentId),
      ));
    } on Object {
      _safeEmit(state.copyWith(
        status: CvStatus.failure,
        message: 'Could not open the CV.',
      ));
    }
  }

  Future<void> loadVersions(String documentId) async {
    final versions = await _docRepo.loadVersions(documentId);
    _safeEmit(state.copyWith(versions: versions));
  }

  /// Loads a specific version into the editor/preview.
  Future<void> openVersion(String versionId) async {
    final version = await _docRepo.loadVersion(versionId);
    if (version == null) return;
    _safeEmit(state.copyWith(
      content: version.content,
      templateId: version.templateId,
      selectedDocument: state.selectedDocument?.copyWith(
        templateId: version.templateId,
      ),
    ));
  }

  Future<void> deleteDocument(String id) async {
    try {
      await _docRepo.deleteDocument(id);
      _safeEmit(const CvState(status: CvStatus.deleted));
      await load();
    } on Object {
      _safeEmit(state.copyWith(
        status: CvStatus.failure,
        message: 'Could not delete the CV.',
      ));
    }
  }
}
