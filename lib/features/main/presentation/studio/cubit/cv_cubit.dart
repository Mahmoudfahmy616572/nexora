import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/cv/cv_content_validator.dart';
import '../../../../../domain/cv/cv_factual_builder.dart';
import '../../../../../domain/cv/cv_readiness_engine.dart';
import '../../../../../domain/entities/career_dna.dart';
import '../../../../../domain/entities/career_target.dart';
import '../../../../../domain/entities/cv_content.dart';
import '../../../../../domain/entities/cv_document.dart';
import '../../../../../domain/entities/job_analysis.dart';
import '../../../../../domain/entities/profile_data.dart';
import '../../../../../domain/entities/user_identity.dart';
import '../../../../../domain/repositories/career_dna_repository.dart';
import '../../../../../domain/repositories/career_target_repository.dart';
import '../../../../../domain/repositories/cv_document_repository.dart';
import '../../../../../domain/repositories/cv_generation_repository.dart';
import '../../../../../domain/repositories/job_analysis_repository.dart';
import '../../../../../domain/repositories/user_identity_repository.dart';

import 'cv_state.dart';

/// Manages the CV Engine: documents, generation, factual fallback, versioning,
/// template switching, and deletion.
class CvCubit extends Cubit<CvState> {
  CvCubit(
    this._docRepo,
    this._genRepo,
    this._dnaRepo,
    this._targetRepo,
    this._analysisRepo, {
    this._identityRepo,
  }) : super(const CvState());

  final CvDocumentRepository _docRepo;
  final CvGenerationRepository _genRepo;
  final CareerDnaRepository _dnaRepo;
  final CareerTargetRepository _targetRepo;
  final JobAnalysisRepository _analysisRepo;
  final UserIdentityRepository? _identityRepo;

  static String _newId() => CareerTarget.newId();

  T? _first<T>(List<T> list, bool Function(T) test) =>
      list.where(test).firstOrNull;

  Future<CareerDna> _ensureDna(CareerDna? cached) async =>
      cached ?? (await _dnaRepo.load()) ?? CareerDna();

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
        if (_identityRepo != null) _identityRepo.load() else Future.value(null),
      ]);
      final dna = await _dnaRepo.load();
      final documents = results[0] as List<CvDocument>;
      final targets = results[1] as List<CareerTarget>;
      final analyses = results[2] as List<JobAnalysis>? ?? const [];
      final identity = results[3] as UserIdentity?;
      _safeEmit(state.copyWith(
        status: documents.isEmpty ? CvStatus.initial : CvStatus.ready,
        documents: documents,
        targets: targets,
        analyses: analyses,
        dna: dna,
        identity: identity,
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
      var content = await _genRepo.generate(
        dna: dna,
        target: target,
        analysis: analysis,
        templateId: state.templateId,
        language: 'en',
        identity: state.identity,
      );
      content = _injectProjectLinks(content, dna);
      content = _injectHeaderLinks(content, state.identity);
      content = _injectExperienceDuration(content, dna);
      final result = CvContentValidator.validate(content, dna, identity: state.identity);
      _safeEmit(state.copyWith(
        status: CvStatus.ready,
        content: content,
        isAiGenerated: true,
        validationIssues: result.issues,
        message: result.valid
            ? null
            : 'AI generation contains some unverified details. '
                'Review carefully or use your Factual CV.',
      ));
    } on Object {
      _safeEmit(state.copyWith(
        status: CvStatus.failure,
        message: 'AI generation is unavailable. You can still use your '
            'Factual CV — built only from verified facts.',
      ));
    }
  }

  static CvContent _injectProjectLinks(CvContent content, CareerDna dna) {
    // Inject project links
    if (dna.profile.projects.isNotEmpty) {
      final linksByName = <String, List<ProjectLink>>{
        for (final p in dna.profile.projects)
          if (p.links.isNotEmpty) _norm(p.name): p.links,
      };
      if (linksByName.isNotEmpty) {
        content = content.copyWith(
          projects: [
            for (final proj in content.projects)
              if (proj.links.isEmpty && linksByName.containsKey(_norm(proj.name)))
                CvProject(
                  name: proj.name,
                  description: proj.description,
                  tech: proj.tech,
                  links: [
                    for (final l in linksByName[_norm(proj.name)]!)
                      CvContactLink(
                        label: l.label.trim().isNotEmpty
                            ? l.label.trim()
                            : ProjectLink.autoLabel(l.url, proj.name),
                        url: l.url.trim(),
                      ),
                  ],
                  bullets: proj.bullets,
                  role: proj.role,
                  date: proj.date,
                  outcome: proj.outcome,
                  keyFeatures: proj.keyFeatures,
                  challenges: proj.challenges,
                  integrations: proj.integrations,
                  source: proj.source,
                )
              else
                proj,
          ],
        );
      }
    }

    // Inject certification links
    if (dna.profile.certifications.isNotEmpty) {
      final linkByName = <String, String>{
        for (final c in dna.profile.certifications)
          if (c.link.trim().isNotEmpty) _norm(c.name): c.link.trim(),
      };
      if (linkByName.isNotEmpty) {
        content = content.copyWith(
          certifications: [
            for (final cert in content.certifications)
              if (cert.link.trim().isEmpty && linkByName.containsKey(_norm(cert.name)))
                CvCertification(
                  name: cert.name,
                  issuer: cert.issuer,
                  year: cert.year,
                  link: linkByName[_norm(cert.name)]!,
                  source: cert.source,
                )
              else
                cert,
          ],
        );
      }
    }

    return content;
  }

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();

  static CvContent _injectHeaderLinks(CvContent content, UserIdentity? identity) {
    if (identity == null) return content;
    final existing = content.header.links;

    // Map known identity URLs to their short labels.
    final urlToLabel = <String, String>{
      if (identity.linkedinUrl.trim().isNotEmpty)
        identity.linkedinUrl.trim().toLowerCase(): 'LinkedIn',
      if (identity.githubUrl.trim().isNotEmpty)
        identity.githubUrl.trim().toLowerCase(): 'GitHub',
      if (identity.portfolioUrl.trim().isNotEmpty)
        identity.portfolioUrl.trim().toLowerCase(): 'Portfolio',
    };

    // Known URL patterns for matching.
    final knownUrlPatterns = urlToLabel.keys.toList();

    bool looksLikeUrl(String s) {
      final lower = s.toLowerCase();
      return lower.contains('://') ||
          lower.startsWith('www.') ||
          RegExp(r'\.(com|io|dev|me|org|net|co|app)\b').hasMatch(lower);
    }

    String? matchKnownUrl(String s) {
      final lower = s.toLowerCase().trim();
      for (final ku in knownUrlPatterns) {
        if (ku == lower || lower.contains(ku) || ku.contains(lower)) return ku;
      }
      return null;
    }

    // Step 1: Fix labels that look like URLs, remove duplicates.
    final seenUrls = <String>{};
    final fixed = <CvContactLink>[];
    for (final l in existing) {
      final urlKey = l.url.trim().toLowerCase();
      final labelLower = l.label.trim().toLowerCase();
      final isDuplicate = !seenUrls.add(urlKey);
      if (isDuplicate) continue;

      if (looksLikeUrl(labelLower)) {
        final matchedKey = matchKnownUrl(urlKey);
        if (matchedKey != null) {
          fixed.add(CvContactLink(label: urlToLabel[matchedKey]!, url: l.url.trim()));
        } else {
          fixed.add(l);
        }
      } else if (urlToLabel.containsKey(urlKey) && labelLower == urlKey) {
        fixed.add(CvContactLink(label: urlToLabel[urlKey]!, url: l.url.trim()));
      } else {
        fixed.add(l);
      }
    }

    // Step 2: Add missing links.
    final knownUrls = {for (final l in fixed) l.url.trim().toLowerCase()};
    final injected = <CvContactLink>[
      ...fixed,
      if (identity.linkedinUrl.trim().isNotEmpty &&
          !knownUrls.contains(identity.linkedinUrl.trim().toLowerCase()))
        CvContactLink(label: 'LinkedIn', url: identity.linkedinUrl.trim()),
      if (identity.githubUrl.trim().isNotEmpty &&
          !knownUrls.contains(identity.githubUrl.trim().toLowerCase()))
        CvContactLink(label: 'GitHub', url: identity.githubUrl.trim()),
      if (identity.portfolioUrl.trim().isNotEmpty &&
          !knownUrls.contains(identity.portfolioUrl.trim().toLowerCase()))
        CvContactLink(label: 'Portfolio', url: identity.portfolioUrl.trim()),
    ];

    // Step 3: Strip raw URLs dumped as plain text in header fields.
    String stripUrlsFromText(String text) {
      if (text.isEmpty) return text;
      var result = text;
      for (final url in urlToLabel.keys) {
        result = result.replaceAll(RegExp(RegExp.escape(url), caseSensitive: false), '');
      }
      // Also strip any remaining https://... or http://... patterns.
      result = result.replaceAll(RegExp(r'https?://\S+'), '');
      // Clean up extra commas, spaces, newlines left behind.
      result = result.replaceAll(RegExp(r'[,\s]+'), ' ').trim();
      return result;
    }

    final cleanSubtitle = stripUrlsFromText(content.header.subtitle);

    final linksChanged = injected.length != fixed.length || !_listEquals(injected, fixed);
    final subtitleChanged = cleanSubtitle != content.header.subtitle;
    if (!linksChanged && !subtitleChanged) return content;
    return content.copyWith(
      header: content.header.copyWith(
        links: linksChanged ? injected : content.header.links,
        subtitle: subtitleChanged ? cleanSubtitle : content.header.subtitle,
      ),
    );
  }

  static bool _listEquals(List<CvContactLink> a, List<CvContactLink> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].label != b[i].label || a[i].url != b[i].url) return false;
    }
    return true;
  }

  static CvContent _injectExperienceDuration(CvContent content, CareerDna dna) {
    if (dna.profile.experience.isEmpty) return content;
    final durationByNorm = <String, int>{
      for (final e in dna.profile.experience)
        if (e.effectiveMonths > 0)
          _norm('${e.role} ${e.company}'): e.effectiveMonths,
    };
    final achievementsByNorm = <String, List<String>>{
      for (final e in dna.profile.experience)
        if (e.achievements.isNotEmpty)
          _norm('${e.role} ${e.company}'): e.achievements,
    };
    if (durationByNorm.isEmpty && achievementsByNorm.isEmpty) return content;

    int? matchDuration(String aiRole, String aiCompany) {
      final key = _norm('$aiRole $aiCompany');
      if (key.isEmpty) return null;
      // Exact match.
      if (durationByNorm.containsKey(key)) return durationByNorm[key];
      // Substring: AI role contains DNA role or vice versa.
      for (final entry in durationByNorm.entries) {
        if (entry.key.length >= 3 && key.length >= 3 &&
            (key.contains(entry.key) || entry.key.contains(key))) {
          return entry.value;
        }
      }
      return null;
    }

    List<String>? matchAchievements(String aiRole, String aiCompany) {
      final key = _norm('$aiRole $aiCompany');
      if (key.isEmpty) return null;
      if (achievementsByNorm.containsKey(key)) return achievementsByNorm[key];
      for (final entry in achievementsByNorm.entries) {
        if (entry.key.length >= 3 && key.length >= 3 &&
            (key.contains(entry.key) || entry.key.contains(key))) {
          return entry.value;
        }
      }
      return null;
    }

    return content.copyWith(
      experience: [
        for (final exp in content.experience)
          CvExperience(
            role: exp.role,
            company: exp.company,
            years: exp.years,
            durationMonths: exp.effectiveMonths > 0
                ? exp.effectiveMonths
                : (matchDuration(exp.role, exp.company) ?? 0),
            startDate: exp.startDate,
            endDate: exp.endDate,
            description: exp.description,
            bullets: exp.bullets,
            location: exp.location,
            technologies: exp.technologies,
            achievements: exp.achievements.isNotEmpty
                ? exp.achievements
                : (matchAchievements(exp.role, exp.company) ?? const []),
            source: exp.source,
          ),
      ],
    );
  }

  /// Regenerates after a failure.
  Future<void> retry() => _generate();

  /// Builds the deterministic, clearly-labelled Factual CV.
  Future<void> useFactual() async {
    final dna = await _ensureDna(state.dna);
    final target = _first(state.targets, (t) => t.id == state.targetId);
    final content = CvFactualBuilder.build(
      dna,
      target: target,
      identity: state.identity,
    );
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

  /// Evaluates CV creation readiness using the given engine.
  CvReadinessReport evaluateReadiness(CvReadinessEngine engine) =>
      engine.evaluate(
        dna: state.dna,
        target: _first(state.targets, (t) => t.id == state.targetId),
        identity: state.identity,
      );

  /// Saves identity data and reloads.
  Future<void> saveIdentity(UserIdentity identity) async {
    if (_identityRepo == null) return;
    await _identityRepo.save(identity);
    _safeEmit(state.copyWith(identity: identity));
  }
}
