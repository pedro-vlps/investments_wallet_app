import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/wallet_theme.dart';
import '../domain/dividend_report.dart';
import 'dividend_format.dart';

class PortfolioReturnChart extends StatelessWidget {
  const PortfolioReturnChart({required this.months, super.key});
  final List<DividendMonth> months;
  static const _withDividends = Color(0xFF95B8FF);
  static const _withoutDividends = Color(0xFFFFD084);

  Widget _legend(String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 18, height: 3, color: color),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: color, fontSize: 12)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final values = months
        .expand((p) => [p.priceReturnPercent, p.totalReturnPercent])
        .whereType<double>()
        .toList();
    if (months.isEmpty || values.isEmpty) {
      return const Text(
        'Sem histórico de avaliação para calcular as linhas de rentabilidade.',
      );
    }
    final minY = values.fold<double>(0, math.min).floorToDouble() - 5;
    final maxY = values.fold<double>(0, math.max).ceilToDouble() + 5;
    final semantics = months
        .where((p) => p.totalReturnPercent != null)
        .map(
          (p) =>
              '${formatDividendMonth(p.month)}: com dividendos ${formatPercent(p.totalReturnPercent!)}, '
              'sem dividendos ${formatPercent(p.priceReturnPercent!)}',
        )
        .join('; ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rentabilidade acumulada (%)',
          style: TextStyle(color: WalletColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 20,
          runSpacing: 8,
          children: [
            _legend('Com dividendos', _withDividends),
            _legend('Sem dividendos', _withoutDividends),
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            // Keep every monthly observation; reduce only axis label density.
            final labelCount = math.max(
              2,
              ((constraints.maxWidth - 76) / 72).floor(),
            );
            final step = math.max(
              1,
              ((months.length - 1) / (labelCount - 1)).ceil(),
            );
            return Semantics(
              label: semantics,
              child: ExcludeSemantics(
                child: SizedBox(
                  key: const ValueKey('portfolio-return-plot'),
                  width: constraints.maxWidth,
                  height: 280,
                  child: LineChart(
                    LineChartData(
                      minX: months.length == 1 ? -0.5 : 0,
                      maxX: months.length == 1
                          ? 0.5
                          : (months.length - 1).toDouble(),
                      minY: minY,
                      maxY: maxY,
                      clipData: const FlClipData.all(),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        horizontalInterval: (maxY - minY) / 4,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: WalletColors.border,
                          strokeWidth: 1,
                        ),
                      ),
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
                            reservedSize: 64,
                            interval: (maxY - minY) / 4,
                            getTitlesWidget: (value, meta) => SideTitleWidget(
                              meta: meta,
                              space: 8,
                              child: Text(
                                '${NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: 1).format(value)}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: WalletColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.round();
                              if ((value - index).abs() > 0.001 ||
                                  index < 0 ||
                                  index >= months.length ||
                                  (index != months.length - 1 &&
                                      index % step != 0)) {
                                return const SizedBox.shrink();
                              }
                              // If the final regular tick is too close to the last month,
                              // prefer the last month so the visible end date stays clear.
                              if (index != 0 &&
                                  index != months.length - 1 &&
                                  months.length - 1 - index < step) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                meta: meta,
                                space: 10,
                                fitInside: SideTitleFitInsideData.fromTitleMeta(
                                  meta,
                                  distanceFromEdge: 0,
                                ),
                                child: Text(
                                  formatDividendMonth(months[index].month),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: WalletColors.muted,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItems: (spots) => spots
                              .map(
                                (spot) => LineTooltipItem(
                                  '${formatDividendMonth(months[spot.x.round()].month)}\n'
                                  '${spot.barIndex == 1 ? 'Com' : 'Sem'} dividendos: ${formatPercent(spot.y)}',
                                  TextStyle(
                                    color: spot.barIndex == 1
                                        ? _withDividends
                                        : _withoutDividends,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      lineBarsData: [
                        for (final withDividends in [false, true])
                          LineChartBarData(
                            color: withDividends
                                ? _withDividends
                                : _withoutDividends,
                            barWidth: 2.5,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                                radius: 2,
                                strokeWidth: 0,
                                color: withDividends
                                    ? _withDividends
                                    : _withoutDividends,
                              ),
                            ),
                            spots: [
                              for (var i = 0; i < months.length; i++)
                                if ((withDividends
                                        ? months[i].totalReturnPercent
                                        : months[i].priceReturnPercent)
                                    case final percent?)
                                  FlSpot(i.toDouble(), percent)
                                else
                                  FlSpot.nullSpot,
                            ],
                          ),
                      ],
                    ),
                    duration: Duration.zero,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
