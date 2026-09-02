import '../entities/career_dna.dart';
import '../entities/career_target.dart';
import '../entities/user_identity.dart';

/// Describes one readiness check result.
class CvReadinessItem {
  const CvReadinessItem({
    required this.key,
    required this.label,
    required this.state,
  });

  final String key;
  final String label;
  final CvReadinessItemState state;
}

enum CvReadinessItemState {
  /// Data present and sufficient.
  ready,

  /// Data present but weak (e.g. title only, no name).
  weak,

  /// Data missing.
  missing,
}

/// Aggregated readiness report for the CV creation gate.
class CvReadinessReport {
  const CvReadinessReport({
    required this.ready,
    required this.stage,
    required this.items,
  });

  final bool ready;
  final CareerStage? stage;
  final List<CvReadinessItem> items;

  /// Human-readable summary of missing items.
  String get summary {
    final missing =
        items.where((i) => i.state == CvReadinessItemState.missing);
    if (missing.isEmpty) return 'All required data is present.';
    return 'Missing: ${missing.map((i) => i.label).join(', ')}.';
  }
}

/// Stateless evaluator that checks whether the user has enough source data
/// to produce a meaningful CV. Never blocks — only reports.
///
/// Stage-aware: fresh graduates are exempt from experience checks.
class CvReadinessEngine {
  const CvReadinessEngine({this.onboarded = false});

  final bool onboarded;

  CvReadinessReport evaluate({
    CareerDna? dna,
    CareerTarget? target,
    UserIdentity? identity,
  }) {
    final items = <CvReadinessItem>[];
    final stage = dna?.stage;

    // --- Identity (name) ---
    items.add(_checkIdentity(identity));

    // --- Target role ---
    items.add(_checkTargetRole(target, dna));

    // --- Experience ---
    items.add(_checkExperience(dna, stage));

    // --- Projects ---
    items.add(_checkProjects(dna));

    // --- Skills ---
    items.add(_checkSkills(dna));

    // --- Education ---
    items.add(_checkEducation(dna, stage));

    final hasBlockingMissing = items.any(
      (i) => i.state == CvReadinessItemState.missing,
    );

    return CvReadinessReport(
      ready: !hasBlockingMissing,
      stage: stage,
      items: items,
    );
  }

  CvReadinessItem _checkIdentity(UserIdentity? identity) {
    final name = identity?.fullName ?? '';
    if (name.isNotEmpty) {
      return const CvReadinessItem(
        key: 'identity',
        label: 'Full name',
        state: CvReadinessItemState.ready,
      );
    }
    return const CvReadinessItem(
      key: 'identity',
      label: 'Full name',
      state: CvReadinessItemState.missing,
    );
  }

  CvReadinessItem _checkTargetRole(CareerTarget? target, CareerDna? dna) {
    final hasRole = target?.role.isNotEmpty == true;
    if (hasRole) {
      return const CvReadinessItem(
        key: 'target_role',
        label: 'Target role',
        state: CvReadinessItemState.ready,
      );
    }
    return const CvReadinessItem(
      key: 'target_role',
      label: 'Target role',
      state: CvReadinessItemState.missing,
    );
  }

  CvReadinessItem _checkExperience(CareerDna? dna, CareerStage? stage) {
    final count = dna?.profile.experience.length ?? 0;
    if (count > 0) {
      return const CvReadinessItem(
        key: 'experience',
        label: 'Work experience',
        state: CvReadinessItemState.ready,
      );
    }
    // Fresh graduates are exempt from experience requirement.
    if (stage == CareerStage.freshGraduate) {
      return const CvReadinessItem(
        key: 'experience',
        label: 'Work experience',
        state: CvReadinessItemState.weak,
      );
    }
    return const CvReadinessItem(
      key: 'experience',
      label: 'Work experience',
      state: CvReadinessItemState.missing,
    );
  }

  CvReadinessItem _checkProjects(CareerDna? dna) {
    final count = dna?.profile.projects.length ?? 0;
    if (count > 0) {
      return const CvReadinessItem(
        key: 'projects',
        label: 'Projects',
        state: CvReadinessItemState.ready,
      );
    }
    return const CvReadinessItem(
      key: 'projects',
      label: 'Projects',
      state: CvReadinessItemState.weak,
    );
  }

  CvReadinessItem _checkSkills(CareerDna? dna) {
    final count = dna?.skills.length ?? 0;
    if (count >= 3) {
      return const CvReadinessItem(
        key: 'skills',
        label: 'Skills',
        state: CvReadinessItemState.ready,
      );
    }
    if (count > 0) {
      return const CvReadinessItem(
        key: 'skills',
        label: 'Skills',
        state: CvReadinessItemState.weak,
      );
    }
    return const CvReadinessItem(
      key: 'skills',
      label: 'Skills',
      state: CvReadinessItemState.missing,
    );
  }

  CvReadinessItem _checkEducation(CareerDna? dna, CareerStage? stage) {
    final count = dna?.profile.education.length ?? 0;
    if (count > 0) {
      return const CvReadinessItem(
        key: 'education',
        label: 'Education',
        state: CvReadinessItemState.ready,
      );
    }
    // Fresh graduates have education at top of mind — it's expected.
    if (stage == CareerStage.freshGraduate) {
      return const CvReadinessItem(
        key: 'education',
        label: 'Education',
        state: CvReadinessItemState.missing,
      );
    }
    // Experienced candidates may have education elsewhere; soft gate.
    return const CvReadinessItem(
      key: 'education',
      label: 'Education',
      state: CvReadinessItemState.weak,
    );
  }
}
