import 'package:flutter/material.dart';

import '../../app/wallet_theme.dart';
import '../domain/dividend_period.dart';
import '../domain/dividend_report.dart';
import 'dividend_controller.dart';
import 'dividend_format.dart';
import 'dividend_payments_table.dart';
import 'dividend_period_picker.dart';
import 'dividend_section.dart';
import 'monthly_dividend_chart.dart';
import 'portfolio_return_chart.dart';

class DividendPage extends StatefulWidget {
  const DividendPage({required this.controller, super.key});
  final DividendController controller;

  @override
  State<DividendPage> createState() => _DividendPageState();
}

class _DividendPageState extends State<DividendPage> {
  DividendPeriod _receivedPeriod = DividendPeriod.inception;
  DividendPeriod _totalPeriod = DividendPeriod.inception;
  DividendPeriod _eventsPeriod = DividendPeriod.inception;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      if (controller.loading) {
        return const Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Carregando dividendos',
          ),
        );
      }
      if (controller.error case final error?) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(padding: const EdgeInsets.all(24), child: Text(error)),
              FilledButton(
                onPressed: controller.load,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        );
      }
      final report = DividendReport(controller.data, controller.asOf);
      final received = report.receivedBySymbol(_receivedPeriod);
      final receivedList = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatMoney(report.receivedTotal(_receivedPeriod)),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Total recebido no período',
            style: TextStyle(color: WalletColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          if (received.isEmpty)
            const Text('Nenhum dividendo recebido no período.')
          else
            for (final entry in received.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      formatMoney(entry.value),
                      style: const TextStyle(color: WalletColors.accent),
                    ),
                  ],
                ),
              ),
        ],
      );
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dividendos',
                  key: ValueKey('dividends-title'),
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
                ),
                if (!controller.data.demo) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Sua carteira usa relatórios importados. A importação de proventos e do histórico de rentabilidade '
                    'ainda não está disponível. Os dados fictícios foram ocultados.',
                    style: TextStyle(
                      color: WalletColors.muted,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                DividendSection(
                  title: 'Dividendos recebidos',
                  filter: DividendPeriodPicker(
                    key: const ValueKey('received-period'),
                    label: 'Período dos dividendos recebidos',
                    value: _receivedPeriod,
                    onChanged: (value) =>
                        setState(() => _receivedPeriod = value),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final chart = MonthlyDividendChart(
                        months: report.monthly(_receivedPeriod),
                      );
                      if (constraints.maxWidth < 700) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            receivedList,
                            const SizedBox(height: 24),
                            chart,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 220, child: receivedList),
                          const SizedBox(width: 28),
                          Expanded(child: chart),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                DividendSection(
                  title: 'Dividendos totais',
                  filter: DividendPeriodPicker(
                    key: const ValueKey('total-period'),
                    label: 'Período dos dividendos totais',
                    value: _totalPeriod,
                    extendedPeriods: true,
                    onChanged: (value) => setState(() => _totalPeriod = value),
                  ),
                  child: PortfolioReturnChart(
                    months: report.monthly(_totalPeriod, withReturns: true),
                  ),
                ),
                const SizedBox(height: 24),
                DividendSection(
                  title: 'Todos os dividendos',
                  filter: DividendPeriodPicker(
                    key: const ValueKey('events-period'),
                    label: 'Período de todos os dividendos',
                    value: _eventsPeriod,
                    onChanged: (value) => setState(() => _eventsPeriod = value),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 40,
                        runSpacing: 16,
                        children: [
                          _PaymentTotal(
                            label: 'Recebidos',
                            value: report.receivedTotal(_eventsPeriod),
                            key: const ValueKey('received-total'),
                          ),
                          _PaymentTotal(
                            label: 'Provisionados',
                            value: report.provisionedTotal(_eventsPeriod),
                            key: const ValueKey('provisioned-total'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DividendPaymentsTable(
                        report: report,
                        period: _eventsPeriod,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _PaymentTotal extends StatelessWidget {
  const _PaymentTotal({required this.label, required this.value, super.key});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: WalletColors.muted)),
      const SizedBox(height: 6),
      Text(
        formatMoney(value),
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      ),
    ],
  );
}
