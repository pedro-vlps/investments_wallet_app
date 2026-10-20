import 'package:flutter/material.dart';

import 'wallet_theme.dart';

class PortfolioNavigation extends StatelessWidget {
  const PortfolioNavigation({
    required this.extended,
    required this.selectedIndex,
    required this.onSelected,
    required this.onToggle,
    required this.reportsExpanded,
    required this.onReportsToggle,
    super.key,
  });
  final bool extended;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback? onToggle;
  final bool reportsExpanded;
  final VoidCallback onReportsToggle;

  @override
  Widget build(BuildContext context) => NavigationRail(
    backgroundColor: WalletColors.surface,
    minWidth: 64,
    minExtendedWidth: 216,
    extended: extended,
    selectedIndex: selectedIndex >= 4 ? 4 : selectedIndex,
    onDestinationSelected: (index) =>
        index == 4 ? onReportsToggle() : onSelected(index),
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
    trailing: reportsExpanded
        ? SizedBox(
            width: extended ? 216 : 64,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _reportLink(
                  4,
                  'Gerenciar relatórios',
                  Icons.folder_open_outlined,
                ),
                _reportLink(
                  5,
                  'Adicionar relatórios',
                  Icons.upload_file_outlined,
                ),
              ],
            ),
          )
        : null,
    destinations: [
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
      NavigationRailDestination(
        icon: Tooltip(
          message: 'Imposto de Renda — BETA',
          child: Badge(
            isLabelVisible: !extended,
            label: const Text('BETA'),
            child: const Icon(Icons.receipt_long_outlined),
          ),
        ),
        selectedIcon: Tooltip(
          message: 'Imposto de Renda — BETA',
          child: Badge(
            isLabelVisible: !extended,
            label: const Text('BETA'),
            child: const Icon(Icons.receipt_long),
          ),
        ),
        label: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Imposto de Renda'),
            SizedBox(width: 8),
            Badge(label: Text('BETA')),
          ],
        ),
      ),
      NavigationRailDestination(
        icon: Tooltip(
          message: 'Relatórios',
          child: Icon(
            reportsExpanded ? Icons.folder_open : Icons.folder_outlined,
          ),
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Relatórios'),
            Icon(
              reportsExpanded ? Icons.expand_less : Icons.expand_more,
              size: 18,
            ),
          ],
        ),
      ),
    ],
  );

  Widget _reportLink(int index, String label, IconData icon) => Padding(
    padding: EdgeInsets.symmetric(horizontal: extended ? 12 : 4, vertical: 4),
    child: extended
        ? ListTile(
            dense: true,
            selected: selectedIndex == index,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: Icon(icon, size: 20),
            title: Text(label),
            onTap: () => onSelected(index),
          )
        : IconButton(
            tooltip: label,
            isSelected: selectedIndex == index,
            onPressed: () => onSelected(index),
            icon: Icon(icon),
          ),
  );
}
