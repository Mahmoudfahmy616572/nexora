import 'package:flutter/material.dart';

import '../../../domain/entities/career_dna.dart';
import '../../../l10n/app_localizations.dart';

/// Localized labels, short descriptions and icons for the pre-auth choices.
/// Kept in one place so the three choice screens stay tiny and consistent.

String goalLabel(AppLocalizations l, CareerGoal g) => switch (g) {
      CareerGoal.job => l.goal_job,
      CareerGoal.cv => l.goal_cv,
      CareerGoal.internship => l.goal_internship,
      CareerGoal.masters => l.goal_masters,
      CareerGoal.scholarship => l.goal_scholarship,
      CareerGoal.careerChange => l.goal_careerChange,
      CareerGoal.improve => l.goal_improve,
      CareerGoal.unsure => l.goal_unsure,
    };

String goalDesc(AppLocalizations l, CareerGoal g) => switch (g) {
      CareerGoal.job => l.goal_job_d,
      CareerGoal.cv => l.goal_cv_d,
      CareerGoal.internship => l.goal_internship_d,
      CareerGoal.masters => l.goal_masters_d,
      CareerGoal.scholarship => l.goal_scholarship_d,
      CareerGoal.careerChange => l.goal_careerChange_d,
      CareerGoal.improve => l.goal_improve_d,
      CareerGoal.unsure => l.goal_unsure_d,
    };

IconData goalIcon(CareerGoal g) => switch (g) {
      CareerGoal.job => Icons.work_outline_rounded,
      CareerGoal.cv => Icons.description_outlined,
      CareerGoal.internship => Icons.school_outlined,
      CareerGoal.masters => Icons.menu_book_outlined,
      CareerGoal.scholarship => Icons.military_tech_outlined,
      CareerGoal.careerChange => Icons.swap_horiz_rounded,
      CareerGoal.improve => Icons.trending_up_rounded,
      CareerGoal.unsure => Icons.explore_outlined,
    };

String stageLabel(AppLocalizations l, CareerStage s) => switch (s) {
      CareerStage.student => l.stage_student,
      CareerStage.freshGraduate => l.stage_freshGraduate,
      CareerStage.earlyCareer => l.stage_earlyCareer,
      CareerStage.experienced => l.stage_experienced,
      CareerStage.careerChanger => l.stage_careerChanger,
    };

String stageDesc(AppLocalizations l, CareerStage s) => switch (s) {
      CareerStage.student => l.stage_student_d,
      CareerStage.freshGraduate => l.stage_freshGraduate_d,
      CareerStage.earlyCareer => l.stage_earlyCareer_d,
      CareerStage.experienced => l.stage_experienced_d,
      CareerStage.careerChanger => l.stage_careerChanger_d,
    };

IconData stageIcon(CareerStage s) => switch (s) {
      CareerStage.student => Icons.school_outlined,
      CareerStage.freshGraduate => Icons.emoji_events_outlined,
      CareerStage.earlyCareer => Icons.rocket_launch_outlined,
      CareerStage.experienced => Icons.workspace_premium_outlined,
      CareerStage.careerChanger => Icons.swap_horiz_rounded,
    };

String fieldLabel(AppLocalizations l, TargetField f) => switch (f) {
      TargetField.programming => l.field_programming,
      TargetField.design => l.field_design,
      TargetField.writing => l.field_writing,
      TargetField.data => l.field_data,
      TargetField.marketing => l.field_marketing,
      TargetField.teaching => l.field_teaching,
      TargetField.business => l.field_business,
      TargetField.engineering => l.field_engineering,
      TargetField.medicine => l.field_medicine,
      TargetField.law => l.field_law,
      TargetField.finance => l.field_finance,
      TargetField.psychology => l.field_psychology,
      TargetField.photography => l.field_photography,
      TargetField.music => l.field_music,
      TargetField.sports => l.field_sports,
      TargetField.hospitality => l.field_hospitality,
      TargetField.agriculture => l.field_agriculture,
      TargetField.science => l.field_science,
      TargetField.sales => l.field_sales,
      TargetField.other => l.field_other,
    };

IconData fieldIcon(TargetField f) => switch (f) {
      TargetField.programming => Icons.code_rounded,
      TargetField.design => Icons.brush_rounded,
      TargetField.writing => Icons.edit_note_rounded,
      TargetField.data => Icons.bar_chart_rounded,
      TargetField.marketing => Icons.campaign_rounded,
      TargetField.teaching => Icons.cast_for_education_rounded,
      TargetField.business => Icons.business_center_rounded,
      TargetField.engineering => Icons.engineering_rounded,
      TargetField.medicine => Icons.medical_services_rounded,
      TargetField.law => Icons.gavel_rounded,
      TargetField.finance => Icons.account_balance_rounded,
      TargetField.psychology => Icons.psychology_rounded,
      TargetField.photography => Icons.photo_camera_rounded,
      TargetField.music => Icons.music_note_rounded,
      TargetField.sports => Icons.sports_rounded,
      TargetField.hospitality => Icons.room_service_rounded,
      TargetField.agriculture => Icons.eco_rounded,
      TargetField.science => Icons.science_rounded,
      TargetField.sales => Icons.sell_rounded,
      TargetField.other => Icons.category_rounded,
    };

const List<CareerGoal> allGoals = CareerGoal.values;
const List<CareerStage> allStages = CareerStage.values;
const List<TargetField> allFields = TargetField.values;
