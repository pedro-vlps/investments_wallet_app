import 'package:flutter/material.dart';

import '../../app/wallet_theme.dart';
import '../domain/dividend_payment.dart';
import '../domain/dividend_period.dart';
import '../domain/dividend_report.dart';
import 'dividend_format.dart';

class DividendPaymentsTable extends StatefulWidget {
  const DividendPaymentsTable({
    required this.report,
    required this.period,
    super.key,
  });
  final DividendReport report;
  final DividendPeriod period;

  @override
  State<DividendPaymentsTable> createState() => _DividendPaymentsTableState();
}

class _DividendPaymentsTableState extends State<DividendPaymentsTable> {
  int _page = 0;
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(covariant DividendPaymentsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period ||
        oldWidget.report.data != widget.report.data) {
      _page = 0;
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.report.payments(widget.period).length;
    final pages = count == 0 ? 1 : (count / DividendReport.pageSize).ceil();
    final payments = widget.report.page(widget.period, _page);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (payments.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Nenhum dividendo no período selecionado.'),
          )
        else
          Scrollbar(
            controller: _scroll,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 16),
              child: DataTable(
                key: const ValueKey('dividend-events-table'),
                dataRowMinHeight: 54,
                dataRowMaxHeight: 54,
                columnSpacing: 24,
                horizontalMargin: 0,
                columns: const [
                  DataColumn(label: Text('TICKER')),
                  DataColumn(label: Text('SITUAÇÃO')),
                  DataColumn(label: Text('TIPO')),
                  DataColumn(label: Text('VALOR / AÇÃO'), numeric: true),
                  DataColumn(label: Text('QUANTIDADE'), numeric: true),
                  DataColumn(label: Text('VALOR TOTAL'), numeric: true),
                  DataColumn(label: Text('DATA COM')),
                  DataColumn(label: Text('DATA EX')),
                  DataColumn(label: Text('PAGAMENTO')),
                ],
                rows: payments
                    .map(
                      (p) => DataRow(
                        key: ValueKey(p.id),
                        cells: [
                          DataCell(Text(p.symbol)),
                          DataCell(
                            Text(
                              p.received
                                  ? 'Recebido'
                                  : p.estimated
                                  ? 'Estimado bruto / a confirmar'
                                  : 'Provisionado',
                              style: TextStyle(
                                color: p.received
                                    ? WalletColors.accent
                                    : const Color(0xFFFFD084),
                              ),
                            ),
                          ),
                          DataCell(Text(dividendKindLabel(p.kind))),
                          DataCell(Text(formatPerShare(p.perShareMicros))),
                          DataCell(
                            Text(
                              p.eligibleQuantity?.toString() ?? 'Não informado',
                            ),
                          ),
                          DataCell(Text(formatMoney(p.amountCents))),
                          DataCell(Text(formatDividendDate(p.cumDate))),
                          DataCell(Text(formatDividendDate(p.exDate))),
                          DataCell(Text(formatDividendDate(p.paymentDate))),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            Text(
              'Página ${_page + 1} de $pages · $count lançamentos',
              key: const ValueKey('dividend-pagination'),
              style: const TextStyle(color: WalletColors.muted, fontSize: 12),
            ),
            IconButton(
              tooltip: 'Página anterior',
              onPressed: _page == 0 ? null : () => setState(() => _page--),
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: 'Próxima página',
              onPressed: _page + 1 >= pages
                  ? null
                  : () => setState(() => _page++),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}
