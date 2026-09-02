part of 'enhance_dna_cubit.dart';

enum EnhanceStatus { initial, loading, loaded, applying, done, error }

class EnhanceDnaState extends Equatable {
  const EnhanceDnaState({
    this.status = EnhanceStatus.initial,
    this.suggestions = const [],
    this.accepted = const {},
    this.rejected = const {},
    this.message,
  });

  final EnhanceStatus status;
  final List<EnhanceSuggestion> suggestions;
  final Set<int> accepted;
  final Set<int> rejected;
  final String? message;

  List<EnhanceSuggestion> get pending =>
      [for (var i = 0; i < suggestions.length; i++)
        if (!accepted.contains(i) && !rejected.contains(i)) suggestions[i]];

  int get pendingCount => pending.length;
  bool get allDecided => pending.isEmpty && suggestions.isNotEmpty;

  @override
  List<Object?> get props => [status, suggestions, accepted, rejected, message];

  EnhanceDnaState copyWith({
    EnhanceStatus? status,
    List<EnhanceSuggestion>? suggestions,
    Set<int>? accepted,
    Set<int>? rejected,
    String? message,
  }) =>
      EnhanceDnaState(
        status: status ?? this.status,
        suggestions: suggestions ?? this.suggestions,
        accepted: accepted ?? this.accepted,
        rejected: rejected ?? this.rejected,
        message: message,
      );
}
