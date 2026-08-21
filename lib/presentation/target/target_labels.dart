import '../../l10n/app_localizations.dart';
import '../../domain/entities/career_target.dart';

String targetTypeLabel(AppLocalizations l10n, TargetType type) => switch (type) {
      TargetType.job => l10n.targetTypeJob,
      TargetType.internship => l10n.targetTypeInternship,
      TargetType.graduateProgram => l10n.targetTypeGraduateProgram,
      TargetType.academicApplication => l10n.targetTypeAcademicApplication,
      TargetType.custom => l10n.targetTypeCustom,
    };
