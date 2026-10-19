import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/portfolio_position.dart';
import '../domain/portfolio_totals.dart';
import 'portfolio_format.dart';
import 'position_table_column.dart';
import 'return_color.dart';

class PositionsTable extends StatefulWidget {
  const PositionsTable({
    required this.positions,
    this.detailed = false,
    super.key,
  });
  final List<PortfolioPosition> positions;
  final bool detailed;

  @override
  State<PositionsTable> createState() => _PositionsTableState();
}

class _PositionsTableState extends State<PositionsTable> {
  final _horizontalScroll = ScrollController();
  PositionTableColumn _sortColumn = PositionTableColumn.symbol;
  bool _ascending = true;

  @override
  void dispose() {
    _horizontalScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final columns = PositionTableColumn.values
        .where((column) => widget.detailed || !column.detailedOnly)
        .toList();
    final positions = sortPositions(
      widget.positions,
      _sortColumn,
      ascending: _ascending,
    );
    final marketValue = PortfolioTotals(widget.positions).marketValueCents;
    return LayoutBuilder(
      builder: (context, constraints) => Scrollbar(
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
              columnSpacing: 28,
              sortColumnIndex: columns.indexOf(_sortColumn),
              sortAscending: _ascending,
              columns: columns
                  .map(
                    (column) => DataColumn(
                      label: Text(column.label),
                      numeric: column.numeric,
                      onSort: (_, ascending) => setState(() {
                        _sortColumn = column;
                        _ascending = ascending;
                      }),
                    ),
                  )
                  .toList(),
              rows: positions
                  .map(
                    (position) => DataRow(
                      key: ValueKey(position.symbol),
                      cells: columns
                          .map((column) => _cell(position, column, marketValue))
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataCell _cell(
    PortfolioPosition position,
    PositionTableColumn column,
    int marketValue,
  ) {
    final text = switch (column) {
      PositionTableColumn.symbol => position.symbol,
      PositionTableColumn.company => position.company,
      PositionTableColumn.quantity => NumberFormat(
        '#,##0.######',
        'pt_BR',
      ).format(position.quantity),
      PositionTableColumn.averageCost => formatMoney(position.averageCostCents),
      PositionTableColumn.invested => formatMoney(position.investedCents),
      PositionTableColumn.quotePrice => formatMoney(position.quote.priceCents),
      PositionTableColumn.marketValue => formatMoney(position.marketValueCents),
      PositionTableColumn.allocation => formatWeight(
        position.allocationPercent(marketValue),
      ),
      PositionTableColumn.gain => formatMoney(position.unrealizedGainCents),
      PositionTableColumn.gainPercent => formatPercent(
        position.unrealizedGainPercent,
      ),
      PositionTableColumn.dividends => formatMoney(
        position.dividendsReceivedCents,
      ),
      PositionTableColumn.totalGain => formatMoney(position.totalGainCents),
      PositionTableColumn.totalGainPercent => formatPercent(
        position.totalGainPercent,
      ),
      PositionTableColumn.quotedAt => formatQuoteTime(position.quote.quotedAt),
      PositionTableColumn.source => position.quote.source,
    };
    final color = switch (column) {
      PositionTableColumn.gain || PositionTableColumn.gainPercent =>
        returnColor(position.unrealizedGainCents),
      PositionTableColumn.totalGain || PositionTableColumn.totalGainPercent =>
        returnColor(position.totalGainCents),
      _ => null,
    };
    return DataCell(
      Text(
        text,
        key: ValueKey('${position.symbol}-${column.name}'),
        style: TextStyle(
          color: color,
          fontWeight: column == PositionTableColumn.symbol
              ? FontWeight.w600
              : null,
        ),
      ),
    );
  }
}
