import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/wallet_theme.dart';
import '../domain/dividend_report.dart';
import 'dividend_format.dart';

class MonthlyDividendChart extends StatefulWidget {
  const MonthlyDividendChart({required this.months, super.key});
  final List<DividendMonth> months;

  @override
  State<MonthlyDividendChart> createState() => _MonthlyDividendChartState();
}

class _MonthlyDividendChartState extends State<MonthlyDividendChart> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final months = widget.months;
    if (months.isEmpty) {
      return const Text('Sem dados para o período selecionado.');
    }
    final rawCashMax = math.max(
      100.0,
      months.fold<double>(0, (m, p) => math.max(m, p.receivedCents / 100)) *
          1.25,
    );
    final cashMax = (rawCashMax / 100).ceilToDouble() * 100;
    Widget axisText(String text) => Text(
      text,
      style: const TextStyle(fontSize: 10, color: WalletColors.muted),
    );
    final semantics = months
        .map(
          (p) =>
              '${formatDividendMonth(p.month)}: ${formatMoney(p.receivedCents)}',
        )
        .join('; ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dividendos recebidos (R\$)',
          style: TextStyle(color: WalletColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) => Semantics(
            label: semantics,
            child: ExcludeSemantics(
              child: Scrollbar(
                controller: _scroll,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    width: math.max(
                      constraints.maxWidth,
                      math.max(420, months.length * 48.0),
                    ),
                    height: 270,
                    child: BarChart(
                      BarChartData(
                        minY: 0,
                        maxY: cashMax,
                        alignment: BarChartAlignment.spaceAround,
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 68,
                              interval: cashMax / 4,
                              getTitlesWidget: (value, _) => axisText(
                                'R\$ ${NumberFormat.compact(locale: 'pt_BR').format(value)}',
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              interval: 1,
                              getTitlesWidget: (value, _) {
                                final index = value.round();
                                return index >= 0 && index < months.length
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: axisText(
                                          formatDividendMonth(
                                            months[index].month,
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          horizontalInterval: cashMax / 4,
                          getDrawingHorizontalLine: (_) => const FlLine(
                            color: WalletColors.border,
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          for (var i = 0; i < months.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: months[i].receivedCents / 100,
                                  width: 18,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                  color: WalletColors.accent.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                              ],
                            ),
                        ],
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                              '${formatDividendMonth(months[group.x].month)}\n${formatMoney(months[group.x].receivedCents)}',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      duration: Duration.zero,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
