import 'package:flutter/material.dart';

import '../../app/wallet_theme.dart';
import '../domain/portfolio_totals.dart';
import 'portfolio_format.dart';
import 'return_color.dart';

class PortfolioSummary extends StatelessWidget {
  const PortfolioSummary({required this.totals, super.key});
  final PortfolioTotals totals;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryCard(
        label: 'Valor da carteira',
        value: formatMoney(totals.marketValueCents),
        caption: 'Com base nas últimas cotações salvas',
        icon: Icons.account_balance_wallet_outlined,
      ),
      _SummaryCard(
        label: 'Total investido',
        value: formatMoney(totals.investedCents),
        caption: 'Custo de aquisição · sem taxas',
        icon: Icons.savings_outlined,
      ),
      _SummaryCard(
        label: 'Resultado não realizado',
        value: formatMoney(totals.gainCents),
        caption: '${formatPercent(totals.gainPercent)} sobre o valor investido',
        icon: Icons.show_chart,
        valueColor: returnColor(totals.gainCents),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return Column(
            children: [
              for (final card in cards)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: card,
                ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    this.valueColor,
  });
  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: WalletColors.surface,
      border: Border.all(color: WalletColors.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 19, color: WalletColors.muted),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: WalletColors.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.7,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          caption,
          style: const TextStyle(color: WalletColors.muted, fontSize: 12),
        ),
      ],
    ),
  );
}
