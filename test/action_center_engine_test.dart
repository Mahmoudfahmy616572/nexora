import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/domain/action_center/action_center.dart';
import 'package:nexora/domain/action_center/action_center_engine.dart';
import 'package:nexora/domain/analysis/career_intelligence_engine.dart';
import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/career_intelligence.dart';
import 'package:nexora/domain/entities/career_target.dart';
import 'package:nexora/domain/entities/cv_document.dart';
import 'package:nexora/domain/entities/cv_content.dart';
import 'package:nexora/domain/entities/cv_evaluation.dart';
import 'package:nexora/domain/entities/job_analysis.dart';
import 'package:nexora/domain/entities/job_application.dart';
import 'package:nexora/domain/entities/opportunity_analysis.dart';
import 'package:nexora/domain/entities/profile_data.dart';

CareerDna _dna({
  CareerStage stage = CareerStage.freshGraduate,
  String role = 'Flutter Developer',
}) =>
    CareerDna(
      stage: stage,
      targetRole: role,
      targetField: TargetField.programming,
      skills: const ['Dart'],
      profile: const ProfileData(
        education: [ProfileEducation(degree: 'BSc', field: 'Computer Science')],
        projects: [ProfileProject(name: 'Portfolio')],
      ),
    );

CareerIntelligence _intelligence(CareerDna dna) => computeCareerIntelligence(
      dna: dna,
      profile: dna.profile,
      skills: dna.skills,
    );

CareerTarget _target({required String id, DateTime? updatedAt}) => CareerTarget(
      id: id,
      userId: 'u',
      type: TargetType.job,
      role: 'Flutter Developer',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: updatedAt ?? DateTime(2024, 1, 1),
    );

JobAnalysis _analysis({required String id, String? targetId, bool withDetail = false}) =>
    JobAnalysis(
      id: id,
      title: 'Senior Flutter Dev',
      company: 'Acme',
      timeAgo: '1d',
      overall: 0.8,
      skills: 0.7,
      experience: 0.6,
      education: 0.7,
      keywords: 0.6,
      strong: const [],
      missing: const [],
      targetId: targetId,
      detail: withDetail ? const OpportunityAnalysis() : null,
    );

CvDocument _document({required String id, String? analysisId}) => CvDocument(
      id: id,
      userId: 'u',
      targetId: 't1',
      templateId: 'minimal',
      title: 'My CV',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      analysisId: analysisId,
    );

CvVersion _version({
  required String id,
  required String documentId,
  int version = 1,
  DateTime? updatedAt,
  String? evaluationId,
}) =>
    CvVersion(
      id: id,
      documentId: documentId,
      userId: 'u',
      version: version,
      content: const CvContent(),
      templateId: 'minimal',
      createdAt: updatedAt ?? DateTime(2024, 1, 1),
      updatedAt: updatedAt ?? DateTime(2024, 1, 1),
      evaluationId: evaluationId,
    );

CvEvaluation _evaluation({required String id, required String versionId}) =>
    CvEvaluation(
      id: id,
      userId: 'u',
      versionId: versionId,
      targetId: 't1',
      overall: 72,
      ats: 70,
      targetAlignment: 70,
      contentStrength: 70,
      evidenceStrength: 70,
      readability: 70,
      clarity: 70,
      structure: 70,
      keywordAlignment: 70,
      skillAlignment: 70,
      sectionCompleteness: 70,
      createdAt: DateTime(2024, 1, 1),
    );

CvSuggestion _suggestion({
  required String id,
  required String evaluationId,
  required String versionId,
  String section = 'summary',
  String targetRequirement = 'Add measurable impact',
  CvSuggestionStatus status = CvSuggestionStatus.pending,
}) =>
    CvSuggestion(
      id: id,
      userId: 'u',
      evaluationId: evaluationId,
      versionId: versionId,
      section: section,
      problem: 'Weak',
      current: 'Did things',
      suggested: 'Led X increasing Y by 30%',
      why: 'Shows impact',
      targetRequirement: targetRequirement,
      status: status,
      createdAt: DateTime(2024, 1, 1),
    );

JobApplication _application({
  required String id,
  String company = 'Acme',
  String role = 'Flutter Developer',
  String status = 'Applied',
}) =>
    JobApplication(
      id: id,
      company: company,
      role: role,
      status: status,
      date: 'Aug 22',
      match: 80,
      ats: 84,
    );

ActionCenterState _derive(ActionCenterInput input) => ActionCenterEngine.derive(input);

void main() {
  group('ActionCenterEngine.derive', () {
    test('1. no DNA -> completeDna', () {
      final d = _derive(const ActionCenterInput());
      expect(d.actionType, ActionType.completeDna);
    });

    test('2. DNA complete but no targets -> defineTarget', () {
      final dna = _dna();
      final d = _derive(ActionCenterInput(
        dna: dna,
        intelligence: _intelligence(dna),
        targets: const [],
      ));
      expect(d.actionType, ActionType.defineTarget);
    });

    test('3. target but no analysis -> analyzeOpportunity', () {
      final dna = _dna();
      final target = _target(id: 't1');
      final d = _derive(ActionCenterInput(
        dna: dna,
        intelligence: _intelligence(dna),
        targets: [target],
        analyses: const [],
      ));
      expect(d.actionType, ActionType.analyzeOpportunity);
      expect(d.targetId, 't1');
    });

    test('4. analysis but no CV -> createCv (carries analysisId)', () {
      final dna = _dna();
      final target = _target(id: 't1');
      final analysis = _analysis(id: 'a1', targetId: 't1');
      final d = _derive(ActionCenterInput(
        dna: dna,
        intelligence: _intelligence(dna),
        targets: [target],
        analyses: [analysis],
        documents: const [],
      ));
      expect(d.actionType, ActionType.createCv);
      expect(d.targetId, 't1');
      expect(d.analysisId, 'a1');
    });

    test('5. CV but no evaluation -> evaluateCv (carries document+version)', () {
      final dna = _dna();
      final target = _target(id: 't1');
      final analysis = _analysis(id: 'a1', targetId: 't1');
      final doc = _document(id: 'doc1', analysisId: 'a1');
      final version = _version(id: 'v1', documentId: 'doc1');
      final d = _derive(ActionCenterInput(
        dna: dna,
        intelligence: _intelligence(dna),
        targets: [target],
        analyses: [analysis],
        documents: [doc],
        versionsByDoc: {'doc1': [version]},
        evaluations: const [],
      ));
      expect(d.actionType, ActionType.evaluateCv);
      expect(d.documentId, 'doc1');
      expect(d.versionId, 'v1');
    });

    test('6. evaluation with actionable pending suggestions -> improveCv', () {
      final dna = _dna();
      final target = _target(id: 't1');
      final analysis = _analysis(id: 'a1', targetId: 't1');
      final doc = _document(id: 'doc1', analysisId: 'a1');
      final version = _version(id: 'v1', documentId: 'doc1', evaluationId: 'e1');
      final evaluation = _evaluation(id: 'e1', versionId: 'v1');
      final suggestion = _suggestion(
        id: 's1',
        evaluationId: 'e1',
        versionId: 'v1',
        section: 'summary',
      );
      final d = _derive(ActionCenterInput(
        dna: dna,
        intelligence: _intelligence(dna),
        targets: [target],
        analyses: [analysis],
        documents: [doc],
        versionsByDoc: {'doc1': [version]},
        evaluations: [evaluation],
        suggestions: [suggestion],
      ));
      expect(d.actionType, ActionType.improveCv);
      expect(d.evaluationId, 'e1');
      expect(d.metadata!['pendingCount'], 1);
    });

    test('7. fully ready -> trackApplications', () {
      final dna = _dna();
      final target = _target(id: 't1');
      final analysis = _analysis(id: 'a1', targetId: 't1');
      final doc = _document(id: 'doc1', analysisId: 'a1');
      final version = _version(id: 'v1', documentId: 'doc1', evaluationId: 'e1');
      final evaluation = _evaluation(id: 'e1', versionId: 'v1');
      final d = _derive(ActionCenterInput(
        dna: dna,
        intelligence: _intelligence(dna),
        targets: [target],
        analyses: [analysis],
        documents: [doc],
        versionsByDoc: {'doc1': [version]},
        evaluations: [evaluation],
        suggestions: const [],
      ));
      expect(d.actionType, ActionType.trackApplications);
      expect(d.metadata!['score'], 72);
    });

    test('8. multiple targets -> deterministic: latest updated wins', () {
      final dna = _dna();
      final older = _target(id: 't1', updatedAt: DateTime(2024, 1, 1));
      final newer = _target(id: 't2', updatedAt: DateTime(2024, 2, 1));
      final d = _derive(ActionCenterInput(
        dna: dna,
        intelligence: _intelligence(dna),
        targets: [older, newer],
        analyses: const [],
      ));
      expect(d.targetId, 't2');
    });

    test('9. multiple CV versions -> latest version is evaluated next', () {
      final dna = _dna();
      final target = _target(id: 't1');
      final analysis = _analysis(id: 'a1', targetId: 't1');
      final doc = _document(id: 'doc1', analysisId: 'a1');
      final oldV = _version(
        id: 'v1',
        documentId: 'doc1',
        version: 1,
        updatedAt: DateTime(2024, 1, 1),
        evaluationId: 'e1',
      );
      final newV = _version(
        id: 'v2',
        documentId: 'doc1',
        version: 2,
        updatedAt: DateTime(2024, 2, 1),
      );
      final evaluation = _evaluation(id: 'e1', versionId: 'v1');
      final d = _derive(ActionCenterInput(
        dna: dna,
        intelligence: _intelligence(dna),
        targets: [target],
        analyses: [analysis],
        documents: [doc],
        versionsByDoc: {'doc1': [oldV, newV]},
        evaluations: [evaluation],
      ));
      expect(d.actionType, ActionType.evaluateCv);
      expect(d.versionId, 'v2');
    });

    test('11. pending cosmetic-only suggestions do not block trackApplications', () {
      final dna = _dna();
      final target = _target(id: 't1');
      final analysis = _analysis(id: 'a1', targetId: 't1');
      final doc = _document(id: 'doc1', analysisId: 'a1');
      final version = _version(id: 'v1', documentId: 'doc1', evaluationId: 'e1');
      final evaluation = _evaluation(id: 'e1', versionId: 'v1');
      final cosmetic = _suggestion(
        id: 's1',
        evaluationId: 'e1',
        versionId: 'v1',
        section: 'formatting',
        targetRequirement: '',
      );
      final d = _derive(ActionCenterInput(
        dna: dna,
        intelligence: _intelligence(dna),
        targets: [target],
        analyses: [analysis],
        documents: [doc],
        versionsByDoc: {'doc1': [version]},
        evaluations: [evaluation],
        suggestions: [cosmetic],
      ));
      expect(d.actionType, ActionType.trackApplications);
    });

    test('12. fresh graduate without experience -> not completeDna (defineTarget)', () {
      final dna = _dna(stage: CareerStage.freshGraduate);
      final d = _derive(ActionCenterInput(
        dna: dna,
        intelligence: _intelligence(dna),
        targets: const [],
      ));
      expect(d.actionType, isNot(ActionType.completeDna));
      expect(d.actionType, ActionType.defineTarget);
    });

    test('13. partial downstream data with no DNA never shows trackApplications', () {
      final target = _target(id: 't1');
      final analysis = _analysis(id: 'a1', targetId: 't1');
      final doc = _document(id: 'doc1', analysisId: 'a1');
      final version = _version(id: 'v1', documentId: 'doc1', evaluationId: 'e1');
      final evaluation = _evaluation(id: 'e1', versionId: 'v1');
      final d = _derive(ActionCenterInput(
        dna: null,
        intelligence: null,
        targets: [target],
        analyses: [analysis],
        documents: [doc],
        versionsByDoc: {'doc1': [version]},
        evaluations: [evaluation],
        suggestions: const [],
      ));
      expect(d.actionType, ActionType.completeDna);
      expect(d.actionType, isNot(ActionType.trackApplications));
    });

    test('14. deterministic: same input yields same decision', () {
      final dna = _dna();
      final input = ActionCenterInput(
        dna: dna,
        intelligence: _intelligence(dna),
        targets: [_target(id: 't1')],
      );
      expect(_derive(input).actionType, _derive(input).actionType);
    });

    test('10. analysis selection prefers one with detail', () {
      final dna = _dna();
      final target = _target(id: 't1');
      final without = _analysis(id: 'a1', targetId: 't1', withDetail: false);
      final withDetail = _analysis(id: 'a2', targetId: 't1', withDetail: true);
      final d = _derive(ActionCenterInput(
        dna: dna,
        intelligence: _intelligence(dna),
        targets: [target],
        analyses: [without, withDetail],
        documents: const [],
      ));
      expect(d.actionType, ActionType.createCv);
      expect(d.analysisId, 'a2');
    });

    test('15. ready + interview-stage application -> prepareInterview', () {
      final dna = _dna();
      final target = _target(id: 't1');
      final analysis = _analysis(id: 'a1', targetId: 't1');
      final doc = _document(id: 'doc1', analysisId: 'a1');
      final version = _version(id: 'v1', documentId: 'doc1', evaluationId: 'e1');
      final evaluation = _evaluation(id: 'e1', versionId: 'v1');
      final d = _derive(ActionCenterInput(
        dna: dna,
        intelligence: _intelligence(dna),
        targets: [target],
        analyses: [analysis],
        documents: [doc],
        versionsByDoc: {'doc1': [version]},
        evaluations: [evaluation],
        suggestions: const [],
        applications: [
          _application(id: 'app2', status: 'Applied'),
          _application(
            id: 'app1',
            company: 'Google',
            role: 'Flutter Engineer',
            status: 'Interview',
          ),
        ],
      ));
      expect(d.actionType, ActionType.prepareInterview);
      expect(d.metadata!['applicationId'], 'app1');
      expect(d.metadata!['targetRole'], 'Flutter Engineer');
      expect(d.metadata!['company'], 'Google');
    });

    test('16. ready + only early-stage applications -> trackApplications', () {
      final dna = _dna();
      final target = _target(id: 't1');
      final analysis = _analysis(id: 'a1', targetId: 't1');
      final doc = _document(id: 'doc1', analysisId: 'a1');
      final version = _version(id: 'v1', documentId: 'doc1', evaluationId: 'e1');
      final evaluation = _evaluation(id: 'e1', versionId: 'v1');
      final d = _derive(ActionCenterInput(
        dna: dna,
        intelligence: _intelligence(dna),
        targets: [target],
        analyses: [analysis],
        documents: [doc],
        versionsByDoc: {'doc1': [version]},
        evaluations: [evaluation],
        suggestions: const [],
        applications: [
          _application(id: 'app3', status: 'Applied'),
          _application(id: 'app4', company: 'Careem', status: 'Rejected'),
        ],
      ));
      expect(d.actionType, ActionType.trackApplications);
    });

    group('Phase 5: practiceInterview', () {
      ActionCenterInput buildReady({bool hasInterviewPrep = false}) {
        final dna = _dna();
        final target = _target(id: 't1');
        final analysis = _analysis(id: 'a1', targetId: 't1');
        final doc = _document(id: 'doc1', analysisId: 'a1');
        final version = _version(id: 'v1', documentId: 'doc1', evaluationId: 'e1');
        final evaluation = _evaluation(id: 'e1', versionId: 'v1');
        return ActionCenterInput(
          dna: dna,
          intelligence: _intelligence(dna),
          targets: [target],
          analyses: [analysis],
          documents: [doc],
          versionsByDoc: {'doc1': [version]},
          evaluations: [evaluation],
          suggestions: const [],
          hasInterviewPrep: hasInterviewPrep,
        );
      }

      test('17. ready + hasInterviewPrep -> practiceInterview (priority 30)',
          () {
        final d = _derive(buildReady(hasInterviewPrep: true));
        expect(d.actionType, ActionType.practiceInterview);
        expect(d.priority, 30);
        expect(d.metadata!['targetRole'], 'Flutter Developer');
      });

      test('18. ready + hasInterviewPrep + interview app -> still practiceInterview',
          () {
        final input = buildReady(hasInterviewPrep: true).copyWith(applications: [
          _application(
            id: 'app1',
            company: 'Google',
            role: 'Flutter Engineer',
            status: 'Interview',
          ),
        ]);
        final d = _derive(input);
        expect(d.actionType, ActionType.practiceInterview);
        expect(d.metadata!['applicationId'], 'app1');
      });

      test('19. ready + interview app but no prep plan -> prepareInterview',
          () {
        final input = buildReady(hasInterviewPrep: false).copyWith(applications: [
          _application(id: 'app1', status: 'Interview'),
        ]);
        final d = _derive(input);
        expect(d.actionType, ActionType.prepareInterview);
        expect(d.priority, 20);
      });
    });
  });
}
