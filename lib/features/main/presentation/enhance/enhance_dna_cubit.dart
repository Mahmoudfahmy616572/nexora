import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/career_dna.dart';
import '../../../../domain/entities/profile_data.dart' show ProfileExperience, ProfileProject;
import '../../../../domain/repositories/career_dna_repository.dart';
import '../../../../data/data_sources/career_remote_data_source.dart';
import 'enhance_suggestion.dart';

part 'enhance_dna_state.dart';

class EnhanceDnaCubit extends Cubit<EnhanceDnaState> {
  EnhanceDnaCubit(this._dnaRepo, this._remote, {required this.dna, required this.gaps, this.targetRole, this.language = 'en'})
      : super(const EnhanceDnaState());

  final CareerDnaRepository _dnaRepo;
  final CareerRemoteDataSource _remote;
  final CareerDna dna;
  final List<String> gaps;
  final String? targetRole;
  final String language;

  Future<void> load() async {
    emit(state.copyWith(status: EnhanceStatus.loading));
    try {
      final expJson = dna.profile.experience.map((e) => {
        'role': e.role,
        'company': e.company,
        'years': e.years,
        'description': e.description,
        'bullets': e.bullets,
        'technologies': e.technologies,
      }).toList();
      final projJson = dna.profile.projects.map((p) => {
        'name': p.name,
        'description': p.description,
        'tech': p.tech,
      }).toList();
      final payload = {
        'dna': {
          'skills': dna.skills,
          'profile': {
            'summary': dna.profile.summary,
            'experience': expJson,
            'projects': projJson,
          },
        },
        'gaps': gaps,
        'target_role': targetRole,
        'language': language,
      };
      final data = await _remote.runAiEnhance(payload);
      print('[ENHANCE] response: suggestions=${(data['suggestions'] as List?)?.length ?? 0}');
      final raw = data['suggestions'] as List? ?? [];
      final suggestions = raw.map((s) {
        final m = s as Map<String, dynamic>;
        return EnhanceSuggestion(
          section: (m['section'] as String?) ?? 'skills',
          action: (m['action'] as String?) ?? 'add',
          itemId: m['itemId'] as String?,
          field: m['field'] as String?,
          current: (m['current'] as String?) ?? '',
          suggested: (m['suggested'] as String?) ?? '',
          reason: (m['reason'] as String?) ?? '',
        );
      }).toList();
      emit(state.copyWith(status: EnhanceStatus.loaded, suggestions: suggestions));
    } catch (e, st) {
      print('[ENHANCE] error: $e');
      print('[ENHANCE] stack: $st');
      emit(state.copyWith(status: EnhanceStatus.error, message: 'e: $e'));
    }
  }

  void accept(int index) {
    final accepted = {...state.accepted, index};
    final rejected = {...state.rejected}..remove(index);
    emit(state.copyWith(accepted: accepted, rejected: rejected));
  }

  void reject(int index) {
    final rejected = {...state.rejected, index};
    final accepted = {...state.accepted}..remove(index);
    emit(state.copyWith(rejected: rejected, accepted: accepted));
  }

  void acceptAll() {
    final all = {for (var i = 0; i < state.suggestions.length; i++) i};
    emit(state.copyWith(accepted: all, rejected: {}));
  }

  Future<CareerDna?> apply() async {
    emit(state.copyWith(status: EnhanceStatus.applying));
    try {
      var updated = dna;
      for (var i = 0; i < state.suggestions.length; i++) {
        if (!state.accepted.contains(i)) continue;
        final s = state.suggestions[i];
        updated = _applyOne(updated, s);
      }
      await _dnaRepo.save(updated);
      emit(state.copyWith(status: EnhanceStatus.done));
      return updated;
    } catch (e) {
      emit(state.copyWith(status: EnhanceStatus.error, message: e.toString()));
      return null;
    }
  }

  CareerDna _applyOne(CareerDna dna, EnhanceSuggestion s) {
    switch (s.section) {
      case 'skills':
        final skills = [...dna.skills];
        if (!skills.any((sk) => sk.toLowerCase() == s.suggested.toLowerCase())) {
          skills.add(s.suggested);
        }
        return dna.copyWith(skills: skills);

      case 'summary':
        return dna.copyWith(
          profile: dna.profile.copyWith(summary: s.suggested),
        );

      case 'experience':
        final exp = [...dna.profile.experience];
        final idx = int.tryParse(s.itemId ?? '');
        if (idx != null && idx < exp.length) {
          final old = exp[idx];
          if (s.field == 'bullets') {
            exp[idx] = ProfileExperience(
              role: old.role, company: old.company, years: old.years,
              durationMonths: old.durationMonths, startDate: old.startDate,
              endDate: old.endDate, location: old.location,
              description: old.description, bullets: [...old.bullets, s.suggested],
              technologies: old.technologies, achievements: old.achievements,
            );
          } else if (s.field == 'technologies') {
            exp[idx] = ProfileExperience(
              role: old.role, company: old.company, years: old.years,
              durationMonths: old.durationMonths, startDate: old.startDate,
              endDate: old.endDate, location: old.location,
              description: old.description, bullets: old.bullets,
              technologies: [...old.technologies, s.suggested],
              achievements: old.achievements,
            );
          } else {
            exp[idx] = ProfileExperience(
              role: old.role, company: old.company, years: old.years,
              durationMonths: old.durationMonths, startDate: old.startDate,
              endDate: old.endDate, location: old.location,
              description: s.suggested, bullets: old.bullets,
              technologies: old.technologies, achievements: old.achievements,
            );
          }
          return dna.copyWith(
            profile: dna.profile.copyWith(experience: exp),
          );
        }
        return dna;

      case 'projects':
        final projs = [...dna.profile.projects];
        final idx = int.tryParse(s.itemId ?? '');
        if (idx != null && idx < projs.length) {
          final old = projs[idx];
          projs[idx] = ProfileProject(
            name: old.name, role: old.role, description: s.suggested,
            tech: old.tech, keyFeatures: old.keyFeatures,
            challenges: old.challenges, integrations: old.integrations,
            outcome: old.outcome, links: old.links,
          );
          return dna.copyWith(
            profile: dna.profile.copyWith(projects: projs),
          );
        }
        return dna;

      default:
        return dna;
    }
  }
}
