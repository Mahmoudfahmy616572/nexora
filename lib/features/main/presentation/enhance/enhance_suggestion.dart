import 'package:equatable/equatable.dart';

class EnhanceSuggestion extends Equatable {
  const EnhanceSuggestion({
    required this.section,
    required this.action,
    this.itemId,
    this.field,
    required this.current,
    required this.suggested,
    required this.reason,
  });

  final String section;
  final String action;
  final String? itemId;
  final String? field;
  final String current;
  final String suggested;
  final String reason;

  @override
  List<Object?> get props => [section, action, itemId, field, current, suggested, reason];
}
