import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nexora/data/data_sources/career_local_data_source.dart';
import 'package:nexora/data/data_sources/career_remote_data_source.dart';
import 'package:nexora/data/repositories/career_dna_repository_impl.dart';
import 'package:nexora/data/repositories/career_repository_impl.dart';
import 'package:nexora/domain/cv/cv_factual_builder.dart';
import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/career_target.dart';
import 'package:nexora/domain/entities/cv_content.dart';
import 'package:nexora/domain/entities/profile_data.dart';
import 'package:nexora/domain/repositories/cv_generation_repository.dart';
import 'package:nexora/features/main/presentation/studio/cubit/cv_cubit.dart';
import 'package:nexora/domain/entities/job_analysis.dart';
import 'package:nexora/features/main/presentation/studio/cubit/cv_state.dart';

class FakeGen implements CvGenerationRepository {
  FakeGen({this.content, this.throws = false});
  final CvContent? content;
  final bool throws;

  @override
  Future<CvContent> generate({
    required CareerDna dna,
    required CareerTarget target,
    JobAnalysis? analysis,
    required String templateId,
    required String language,
  }) {
    if (throws) throw Exception('unavailable');
    return Future.value(content ?? CvFactualBuilder.build(dna, target: target));
  }
}

CareerDna dnaWithFacts() => CareerDna(
      targetRole: 'Flutter Developer',
      skills: const ['Dart', 'Flutter'],
      profile: ProfileData(
        summary: 'Built apps.',
        experience: const [
          ProfileExperience(role: 'Intern', company: 'ACME', years: 1)
        ],
        projects: const [
          ProfileProject(name: 'Delivery', description: 'Food app', tech: ['Flutter'])
        ],
      ),
    );

Future<CvCubit> build(FakeGen gen, {CareerDna? dna}) async {
  final prefs = await SharedPreferences.getInstance();
  final remote = CareerRemoteDataSource();
  final local = CareerLocalDataSource(prefs);
  final dnaRepo = CareerDnaRepositoryImpl(remote: remote, local: local);
  final targetRepo = CareerTargetRepositoryImpl(remote, local);
  await targetRepo.create(CareerTarget(
    id: 't1',
    userId: 'u',
    type: TargetType.job,
    role: 'Flutter Dev',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  ));
  if (dna != null) await local.writeCareerDna(dna.toRow());
  final cubit = CvCubit(
    CvDocumentRepositoryImpl(remote, local),
    gen,
    dnaRepo,
    targetRepo,
    JobAnalysisRepositoryImpl(remote, local),
  );
  await cubit.load();
  return cubit;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('generation unavailable -> failure state with factual fallback', () async {
    final cubit = await build(FakeGen(throws: true));
    await cubit.startCreation(
        title: 'CV', templateId: 'nexoraMinimal', targetId: 't1');
    expect(cubit.state.status, CvStatus.failure);
    expect(cubit.state.content, isNull);
    expect(cubit.state.message, contains('Factual'));

    await cubit.useFactual();
    expect(cubit.state.status, CvStatus.ready);
    expect(cubit.state.isAiGenerated, isFalse);
    expect(cubit.state.content, isNotNull);
  });

  test('valid generation is accepted and marked as AI tailored', () async {
    final cubit = await build(FakeGen(content: null), dna: dnaWithFacts());
    await cubit.startCreation(
        title: 'CV', templateId: 'nexoraMinimal', targetId: 't1');
    expect(cubit.state.status, CvStatus.ready);
    expect(cubit.state.isAiGenerated, isTrue);
    expect(cubit.state.content!.projects.single.name, 'Delivery');
  });

  test('fabricated generation is rejected with validation issues', () async {
    final fabricated = CvContent(
        experience: const [CvExperience(role: 'CEO', company: 'Imaginary')]);
    final cubit = await build(FakeGen(content: fabricated), dna: dnaWithFacts());
    await cubit.startCreation(
        title: 'CV', templateId: 'nexoraMinimal', targetId: 't1');
    expect(cubit.state.status, CvStatus.failure);
    expect(cubit.state.validationIssues, isNotEmpty);
    expect(cubit.state.message, contains('verified'));

    await cubit.useFactual();
    expect(cubit.state.status, CvStatus.ready);
  });

  test('switching template preserves content', () async {
    final cubit = await build(FakeGen(content: null), dna: dnaWithFacts());
    await cubit.startCreation(
        title: 'CV', templateId: 'nexoraMinimal', targetId: 't1');
    final before = cubit.state.content;
    cubit.switchTemplate('nexoraModern');
    expect(cubit.state.templateId, 'nexoraModern');
    expect(cubit.state.content, before);
  });

  test('save creates a version and saving again increments it', () async {
    final cubit = await build(FakeGen(content: null), dna: dnaWithFacts());
    await cubit.startCreation(
        title: 'CV', templateId: 'nexoraMinimal', targetId: 't1');
    await cubit.save();
    expect(cubit.state.selectedDocument, isNotNull);
    expect(cubit.state.versions.length, 1);
    expect(cubit.state.versions.first.version, 1);

    await cubit.save();
    expect(cubit.state.versions.length, 2);
    expect(cubit.state.versions.last.version, 2);
  });

  test('manual edit changes content but never mutates CareerDna', () async {
    final cubit = await build(FakeGen(content: null), dna: dnaWithFacts());
    await cubit.startCreation(
        title: 'CV', templateId: 'nexoraMinimal', targetId: 't1');
    await cubit.useFactual();
    final originalCompany = cubit.state.dna!.profile.experience.single.company;
    cubit.editContent(cubit.state.content!.copyWith(summary: 'edited'));
    expect(cubit.state.content!.summary, 'edited');
    expect(cubit.state.dna!.profile.experience.single.company, originalCompany);
  });

  test('opening a saved document does not create a new version', () async {
    final cubit = await build(FakeGen(content: null), dna: dnaWithFacts());
    await cubit.startCreation(
        title: 'CV', templateId: 'nexoraMinimal', targetId: 't1');
    await cubit.save();
    final id = cubit.state.selectedDocument!.id;
    final versionsAfterSave = cubit.state.versions.length;
    await cubit.openDocument(id);
    expect(cubit.state.versions.length, versionsAfterSave);
  });

  test('delete removes the document', () async {
    final cubit = await build(FakeGen(content: null), dna: dnaWithFacts());
    await cubit.startCreation(
        title: 'CV', templateId: 'nexoraMinimal', targetId: 't1');
    await cubit.save();
    final id = cubit.state.selectedDocument!.id;
    await cubit.deleteDocument(id);
    expect(cubit.state.documents.any((d) => d.id == id), isFalse);
  });
}
