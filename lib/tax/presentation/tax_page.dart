import 'package:flutter/material.dart';

import 'tax_annual_panel.dart';
import 'tax_assessment_panel.dart';
import 'tax_controller.dart';
import 'tax_planning_panel.dart';
import 'tax_rules_card.dart';

class TaxPage extends StatefulWidget {
  const TaxPage({required this.controller, super.key});
  final TaxController controller;
  @override
  State<TaxPage> createState() => _TaxPageState();
}

class _TaxPageState extends State<TaxPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      return ListView(
        key: const PageStorageKey('tax-scroll'),
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Imposto de Renda',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TaxRulesCard(controller: controller),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<int>(
                  key: ValueKey(controller.year),
                  initialValue: controller.year,
                  decoration: const InputDecoration(
                    labelText: 'Ano-calendário',
                  ),
                  items: [
                    for (
                      var year = controller.clock().year;
                      year >= 2025;
                      year--
                    )
                      DropdownMenuItem(value: year, child: Text('$year')),
                  ],
                  onChanged: controller.busy
                      ? null
                      : (year) {
                          if (year != null) controller.loadYear(year);
                        },
                ),
              ),
              ToggleButtons(
                isSelected: [for (var i = 0; i < 3; i++) i == _tab],
                onPressed: (index) => setState(() => _tab = index),
                borderRadius: BorderRadius.circular(8),
                children: const [
                  Padding(padding: EdgeInsets.all(12), child: Text('Apuração')),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Planejamento'),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Declaração'),
                  ),
                ],
              ),
            ],
          ),
          if (controller.busy)
            const LinearProgressIndicator(
              semanticsLabel: 'Carregando registros fiscais',
            ),
          if (controller.error case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 24),
          switch (_tab) {
            1 => TaxPlanningPanel(
              key: ValueKey((controller.year, controller.data)),
              controller: controller,
            ),
            2 => TaxAnnualPanel(controller: controller),
            _ => TaxAssessmentPanel(controller: controller),
          },
        ],
      );
    },
  );
}
