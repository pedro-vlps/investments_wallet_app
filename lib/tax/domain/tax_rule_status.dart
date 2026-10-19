import 'dart:convert';

import 'tax_rules.dart';

class TaxRuleStatus {
  const TaxRuleStatus({
    this.checkedAt,
    this.attemptedAt,
    this.online,
    this.changedSources = const [],
    this.problem,
    this.deadlineYear,
    this.deadline,
  });
  final DateTime? checkedAt;
  final DateTime? attemptedAt;
  final bool? online;
  final List<String> changedSources;
  final String? problem;
  final int? deadlineYear;
  final DateTime? deadline;

  bool needsCheck(DateTime now) =>
      checkedAt == null ||
      checkedAt!.isAfter(now) ||
      !now.isBefore(TaxRules.nextReview(checkedAt!));

  DateTime? annualDeadline(int year) {
    if (deadlineYear == year) return deadline;
    if (year == 2026) return DateTime(2026, 5, 29);
    return null;
  }

  /// January is preparation, not the official opening of transmission.
  bool annualExportAvailable(DateTime now) {
    final end = annualDeadline(now.year) ?? DateTime(now.year, 6, 30);
    final today = DateTime(now.year, now.month, now.day);
    return !today.isAfter(end);
  }

  String encode() => jsonEncode({
    'revision': TaxRules.revision,
    'checkedAt': checkedAt?.toIso8601String(),
    'attemptedAt': attemptedAt?.toIso8601String(),
    'changedSources': changedSources,
    'problem': problem,
    'deadlineYear': deadlineYear,
    'deadline': deadline?.toIso8601String(),
  });

  factory TaxRuleStatus.decode(String? value) {
    if (value == null) return const TaxRuleStatus();
    final data = jsonDecode(value) as Map<String, dynamic>;
    if (data['revision'] != TaxRules.revision) return const TaxRuleStatus();
    return TaxRuleStatus(
      checkedAt: DateTime.tryParse(data['checkedAt'] as String? ?? ''),
      attemptedAt: DateTime.tryParse(data['attemptedAt'] as String? ?? ''),
      changedSources: (data['changedSources'] as List<dynamic>).cast<String>(),
      problem: data['problem'] as String?,
      deadlineYear: data['deadlineYear'] as int?,
      deadline: DateTime.tryParse(data['deadline'] as String? ?? ''),
    );
  }
}
