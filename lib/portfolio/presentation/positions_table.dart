import 'package:flutter/material.dart';

import '../../app/wallet_theme.dart';
import '../domain/portfolio_position.dart';
import 'portfolio_format.dart';

class PositionsTable extends StatefulWidget {
  const PositionsTable({required this.positions, super.key});
  final List<PortfolioPosition> positions;

  @override
  State<PositionsTable> createState() => _PositionsTableState();
}

class _PositionsTableState extends State<PositionsTable> {
  final _horizontalScroll = ScrollController();

  @override
  void dispose() {
    _horizontalScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      return Scrollbar(
        controller: _horizontalScroll,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontalScroll,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              horizontalMargin: 24,
              columnSpacing: 30,
              columns: const [
                DataColumn(label: Text('ATIVO')),
                DataColumn(label: Text('QUANTIDADE'), numeric: true),
                DataColumn(label: Text('PREÇO MÉDIO'), numeric: true),
                DataColumn(label: Text('ÚLTIMA COTAÇÃO'), numeric: true),
                DataColumn(label: Text('VALOR ATUAL'), numeric: true),
                DataColumn(label: Text('RESULTADO'), numeric: true),
                DataColumn(label: Text('COTAÇÃO EM')),
              ],
              rows: widget.positions.map((position) {
                final gainColor = position.unrealizedGainCents >= 0
                    ? WalletColors.accent
                    : WalletColors.loss;
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: WalletColors.accent.withValues(
                                alpha: 0.09,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              position.symbol.substring(0, 2),
                              style: const TextStyle(
                                color: WalletColors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                position.symbol,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                position.company,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: WalletColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text('${position.quantity}')),
                    DataCell(Text(formatMoney(position.averageCostCents))),
                    DataCell(Text(formatMoney(position.quote.priceCents))),
                    DataCell(Text(formatMoney(position.marketValueCents))),
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatMoney(position.unrealizedGainCents),
                            style: TextStyle(color: gainColor),
                          ),
                          Text(
                            formatPercent(position.unrealizedGainPercent),
                            style: TextStyle(fontSize: 12, color: gainColor),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatQuoteTime(position.quote.quotedAt),
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            position.quote.source,
                            style: const TextStyle(
                              fontSize: 11,
                              color: WalletColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      );
    },
  );
}
