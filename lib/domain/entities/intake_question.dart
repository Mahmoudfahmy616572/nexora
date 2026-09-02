import '../../domain/entities/career_dna.dart';
import '../../l10n/app_localizations.dart';

/// How a single intake question collects its answer.
enum IntakeInputType {
  shortText,
  longText,
  tags,
  stringList,
  structuredList,
  links,
}

/// Logical grouping used to lay out the form and for analytics.
enum IntakeCategory {
  identity,
  education,
  experience,
  projects,
  skills,
  achievements,
  languages,
  certifications,
  careerChanger,
  context,
}

/// A sub-field inside a [IntakeInputType.structuredList] question (e.g. the
/// degree / field rows of an education entry).
class ListField {
  const ListField({
    required this.name,
    required this.inputType,
    required this.label,
    this.options,
  });

  final String name;
  final IntakeInputType inputType;
  final String Function(AppLocalizations) label;
  final List<String>? options;
}

/// A single adaptive-intake question, defined as structured configuration rather
/// than hardcoded UI. The [question]/[help]/[placeholder] text are resolved
/// through [AppLocalizations] so the bank stays fully localized.
class IntakeQuestion {
  const IntakeQuestion({
    required this.id,
    required this.category,
    required this.key,
    required this.inputType,
    required this.question,
    this.help,
    this.placeholder,
    this.required = false,
    this.stages = CareerStage.values,
    this.goals = CareerGoal.values,
    this.fields = TargetField.values,
    this.condition,
    this.options,
    this.optionLabels,
    this.listSchema,
    this.maxItems,
  });

  final String id;
  final IntakeCategory category;
  final String key;

  /// Where the answer is persisted on the [CareerDna].
  final IntakeInputType inputType;
  final String Function(AppLocalizations) question;
  final String? Function(AppLocalizations)? help;
  final String? Function(AppLocalizations)? placeholder;
  final bool required;

  /// Stages this question applies to (empty list => all).
  final List<CareerStage> stages;

  /// Goals this question applies to (empty list => all).
  final List<CareerGoal> goals;

  /// Target fields this question applies to (empty list => all).
  final List<TargetField> fields;

  /// Optional conditional visibility based on already-collected answers.
  final bool Function(Map<String, dynamic> answers)? condition;

  /// Options for [IntakeInputType.shortText] when rendered as a choice.
  final List<String>? options;

  /// Localized labels for [options]; when omitted the raw option value is shown.
  final List<String> Function(AppLocalizations)? optionLabels;

  /// Sub-fields for [IntakeInputType.structuredList].
  final List<ListField>? listSchema;

  /// Optional cap on list length.
  final int? maxItems;

  bool appliesTo({
    required CareerStage? stage,
    required Set<CareerGoal> goals,
    required TargetField? field,
    required Map<String, dynamic> answers,
  }) {
    if (stages.isNotEmpty && stage != null && !stages.contains(stage)) {
      return false;
    }
    if (goals.isNotEmpty && this.goals.isNotEmpty && this.goals.toSet().intersection(goals).isEmpty) {
      return false;
    }
    if (fields.isNotEmpty && field != null && !fields.contains(field)) {
      return false;
    }
    if (condition != null && !condition!(answers)) return false;
    return true;
  }
}
