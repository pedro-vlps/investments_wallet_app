import 'package:flutter/material.dart';
import '../dividends/presentation/dividend_controller.dart';
import '../dividends/presentation/dividend_page.dart';

import '../portfolio/presentation/portfolio_controller.dart';
import '../portfolio/presentation/portfolio_page.dart';
import 'portfolio_navigation.dart';

class PortfolioWorkspace extends StatefulWidget {
  const PortfolioWorkspace({
    required this.controller,
    required this.dividendController,
    super.key,
  });
  final PortfolioController controller;
  final DividendController dividendController;

  @override
  State<PortfolioWorkspace> createState() => _PortfolioWorkspaceState();
}

class _PortfolioWorkspaceState extends State<PortfolioWorkspace> {
  bool _extended = true;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final canExtend = constraints.maxWidth >= 800;
          return Row(
            children: [
              PortfolioNavigation(
                extended: canExtend && _extended,
                selectedIndex: _selectedIndex,
                onSelected: (index) => setState(() => _selectedIndex = index),
                onToggle: canExtend
                    ? () => setState(() => _extended = !_extended)
                    : null,
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex == 2 ? 1 : 0,
                  children: [
                    TickerMode(
                      enabled: _selectedIndex != 2,
                      child: PortfolioPage(
                        controller: widget.controller,
                        detailed: _selectedIndex == 1,
                      ),
                    ),
                    TickerMode(
                      enabled: _selectedIndex == 2,
                      child: DividendPage(
                        controller: widget.dividendController,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
