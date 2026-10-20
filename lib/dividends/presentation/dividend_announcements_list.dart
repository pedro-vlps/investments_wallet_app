import 'package:flutter/material.dart';
import '../domain/dividend_market_data.dart';
import '../domain/dividend_payment.dart';
import 'dividend_format.dart';

class DividendAnnouncementsList extends StatelessWidget {
  const DividendAnnouncementsList({
    required this.announcements,
    required this.asOf,
    super.key,
  });
  final List<DividendAnnouncement> announcements;
  final DateTime asOf;

  @override
  Widget build(BuildContext context) {
    final today = DateTime(asOf.year, asOf.month, asOf.day);
    final upcoming =
        announcements.where((a) => !a.paymentDate.isBefore(today)).toList()
          ..sort((a, b) => a.paymentDate.compareTo(b.paymentDate));
    return ExpansionTile(
      title: const Text('Próximos anúncios consultados na API'),
      subtitle: Text(
        '${upcoming.length} anúncio(s) · o anúncio não confirma recebimento ou quantidade elegível',
      ),
      children: [
        if (upcoming.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Nenhum anúncio futuro disponível nos dados consultados.',
            ),
          ),
        for (final announcement in upcoming.take(20))
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${announcement.symbol} · ${dividendKindLabel(announcement.kind)} · '
                '${formatPerShare(announcement.perShareMicros)} por ação/cota\n'
                'Data com: ${formatDividendDate(announcement.cumDate)} · '
                'Data ex: ${formatDividendDate(announcement.exDate)} · '
                'Pagamento: ${formatDividendDate(announcement.paymentDate)}',
              ),
            ),
          ),
        if (upcoming.length > 20)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Exibindo os próximos 20 anúncios.'),
          ),
      ],
    );
  }
}
