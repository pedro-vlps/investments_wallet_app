import 'dividend_payment.dart';

class DividendAnnouncement {
  const DividendAnnouncement({
    required this.symbol,
    required this.kind,
    required this.paymentDate,
    required this.cumDate,
    required this.perShareMicros,
    this.exDate,
  });
  final String symbol;
  final DividendKind kind;
  final DateTime paymentDate;
  final DateTime cumDate;
  final DateTime? exDate;
  final int perShareMicros;
  Map<String, Object?> toJson() => {
    'symbol': symbol,
    'kind': kind.name,
    'payment': paymentDate.toIso8601String(),
    'cum': cumDate.toIso8601String(),
    'ex': exDate?.toIso8601String(),
    'rate': perShareMicros,
  };
  factory DividendAnnouncement.fromJson(Map<String, dynamic> value) =>
      DividendAnnouncement(
        symbol: value['symbol'] as String,
        kind: DividendKind.values.byName(value['kind'] as String),
        paymentDate: DateTime.parse(value['payment'] as String),
        cumDate: DateTime.parse(value['cum'] as String),
        exDate: value['ex'] == null
            ? null
            : DateTime.parse(value['ex'] as String),
        perShareMicros: value['rate'] as int,
      );
}

class DividendMarketData {
  const DividendMarketData({
    required this.symbol,
    required this.checkedAt,
    this.announcements = const [],
    this.closes = const {},
    this.warnings = const [],
    this.hasCorporateActions = false,
    this.announcementsUpdated = true,
    this.pricesUpdated = true,
  });
  final String symbol;
  final DateTime checkedAt;
  final List<DividendAnnouncement> announcements;
  // Original unadjusted daily closing prices, in cents, keyed by YYYY-MM-DD.
  final Map<String, int> closes;
  final List<String> warnings;
  final bool hasCorporateActions;
  final bool announcementsUpdated;
  final bool pricesUpdated;
  Map<String, Object?> toJson() => {
    'symbol': symbol,
    'checked': checkedAt.toIso8601String(),
    'announcements': announcements.map((a) => a.toJson()).toList(),
    'closes': closes,
    'warnings': warnings,
    'corporateActions': hasCorporateActions,
    'announcementsUpdated': announcementsUpdated,
    'pricesUpdated': pricesUpdated,
  };
  factory DividendMarketData.fromJson(Map<String, dynamic> value) =>
      DividendMarketData(
        symbol: value['symbol'] as String,
        checkedAt: DateTime.parse(value['checked'] as String),
        announcements: (value['announcements'] as List)
            .map(
              (a) => DividendAnnouncement.fromJson(a as Map<String, dynamic>),
            )
            .toList(),
        closes: (value['closes'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, v as int),
        ),
        warnings: (value['warnings'] as List).cast<String>(),
        hasCorporateActions: value['corporateActions'] as bool,
        announcementsUpdated: value['announcementsUpdated'] as bool,
        pricesUpdated: value['pricesUpdated'] as bool,
      );
}

class DividendSyncException implements Exception {
  const DividendSyncException(this.message);
  final String message;
}
