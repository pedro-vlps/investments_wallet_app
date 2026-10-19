import 'package:flutter/material.dart';

import 'wallet_theme.dart';

class PortfolioNavigation extends StatelessWidget {
  const PortfolioNavigation({
    required this.extended,
    required this.selectedIndex,
    required this.onSelected,
    required this.onToggle,
    super.key,
  });
  final bool extended;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) => NavigationRail(
    backgroundColor: WalletColors.surface,
    minWidth: 64,
    minExtendedWidth: 216,
    extended: extended,
    selectedIndex: selectedIndex,
    onDestinationSelected: onSelected,
    leading: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: IconButton(
        tooltip: onToggle == null
            ? 'Menu compacto nesta largura'
            : extended
            ? 'Recolher menu'
            : 'Expandir menu',
        onPressed: onToggle,
        icon: Icon(extended ? Icons.menu_open : Icons.menu),
      ),
    ),
    destinations: const [
      NavigationRailDestination(
        icon: Tooltip(
          message: 'Tabela resumida',
          child: Icon(Icons.dashboard_outlined),
        ),
        selectedIcon: Tooltip(
          message: 'Tabela resumida',
          child: Icon(Icons.dashboard),
        ),
        label: Text('Tabela resumida'),
      ),
      NavigationRailDestination(
        icon: Tooltip(
          message: 'Tabela detalhada',
          child: Icon(Icons.table_chart_outlined),
        ),
        selectedIcon: Tooltip(
          message: 'Tabela detalhada',
          child: Icon(Icons.table_chart),
        ),
        label: Text('Tabela detalhada'),
      ),
      NavigationRailDestination(
        icon: Tooltip(
          message: 'Dividendos',
          child: Icon(Icons.payments_outlined),
        ),
        selectedIcon: Tooltip(
          message: 'Dividendos',
          child: Icon(Icons.payments),
        ),
        label: Text('Dividendos'),
      ),
    ],
  );
}
