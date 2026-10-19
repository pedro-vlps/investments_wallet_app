import 'package:flutter/material.dart';

import '../portfolio/presentation/portfolio_controller.dart';
import '../portfolio/presentation/portfolio_page.dart';
import 'portfolio_navigation.dart';

class PortfolioWorkspace extends StatefulWidget {
  const PortfolioWorkspace({required this.controller, super.key});
  final PortfolioController controller;

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
                child: PortfolioPage(
                  controller: widget.controller,
                  detailed: _selectedIndex == 1,
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
