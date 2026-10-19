import 'package:flutter/material.dart';
import '../dividends/presentation/dividend_controller.dart';
import '../dividends/presentation/dividend_page.dart';
import '../reports/presentation/report_controller.dart';
import '../reports/presentation/report_management_page.dart';
import '../reports/presentation/report_upload_page.dart';

import '../portfolio/presentation/portfolio_controller.dart';
import '../portfolio/presentation/portfolio_page.dart';
import 'portfolio_navigation.dart';

class PortfolioWorkspace extends StatefulWidget {
  const PortfolioWorkspace({
    required this.controller,
    required this.dividendController,
    required this.reportController,
    super.key,
  });
  final PortfolioController controller;
  final DividendController dividendController;
  final ReportController reportController;

  @override
  State<PortfolioWorkspace> createState() => _PortfolioWorkspaceState();
}

class _PortfolioWorkspaceState extends State<PortfolioWorkspace> {
  bool _extended = true;
  int _selectedIndex = 0;
  bool _reportsExpanded = false;

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
                reportsExpanded: _reportsExpanded,
                onReportsToggle: () =>
                    setState(() => _reportsExpanded = !_reportsExpanded),
                onSelected: (index) => setState(() => _selectedIndex = index),
                onToggle: canExtend
                    ? () => setState(() => _extended = !_extended)
                    : null,
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex < 2 ? 0 : _selectedIndex - 1,
                  children: [
                    TickerMode(
                      enabled: _selectedIndex < 2,
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
                    ReportManagementPage(
                      controller: widget.reportController,
                      onAdd: () => setState(() {
                        _selectedIndex = 4;
                        _reportsExpanded = true;
                      }),
                    ),
                    ReportUploadPage(controller: widget.reportController),
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
