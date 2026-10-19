import 'package:flutter/material.dart';

import '../../financial_display/number_format.dart';
import '../domain/tax_assessment.dart';
import '../domain/tax_planning.dart';
import 'tax_controller.dart';
import 'tax_money_field.dart';

class TaxPlanningPanel extends StatefulWidget {
  const TaxPlanningPanel({required this.controller, super.key});
  final TaxController controller;
  @override
  State<TaxPlanningPanel> createState() => _TaxPlanningPanelState();
}

class _TaxPlanningPanelState extends State<TaxPlanningPanel> {
  final _form = GlobalKey<FormState>();
  final _result = TextEditingController(text: '0,00');
  final _sales = TextEditingController(text: '0,00');
  TaxPlanningGroup _group = TaxPlanningGroup.stock;
  late int _month = widget.controller.clock().month;
  TaxAssessment? _before;
  TaxAssessment? _after;
  String? _error;

  @override
  void initState() {
    super.initState();
    _result.addListener(_clearScenario);
    _sales.addListener(_clearScenario);
  }

  void _clearScenario() {
    if (_after != null) setState(() => _after = null);
  }

  @override
  void dispose() {
    _result.dispose();
    _sales.dispose();
    super.dispose();
  }

  void _simulate() {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _error = null;
      _after = null;
      try {
        final controller = widget.controller;
        _before = simulateTaxMonth(
          year: controller.year,
          month: _month,
          opening: controller.data.opening,
          recorded: controller.data.months,
          group: _group,
          additionalResult: 0,
          additionalStockSales: 0,
        );
        _after = simulateTaxMonth(
          year: controller.year,
          month: _month,
          opening: controller.data.opening,
          recorded: controller.data.months,
          group: _group,
          additionalResult: parseTaxMoney(_result.text, signed: true),
          additionalStockSales: parseTaxMoney(_sales.text),
        );
      } on FormatException catch (e) {
        _error = e.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Planejamento de imposto',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      const Text(
        'Compare um resultado líquido adicional com o mês registrado. '
        'Informe prejuízo com sinal negativo. A simulação não registra vendas nem recomenda ordens. '
        'Ela considera os saldos de meses anteriores e os custos já incluídos no resultado informado.',
      ),
      const SizedBox(height: 12),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Form(
          key: _form,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                initialValue: _month,
                decoration: const InputDecoration(labelText: 'Mês do cenário'),
                items: [
                  for (var m = 1; m <= 12; m++)
                    DropdownMenuItem(
                      value: m,
                      child: Text('$m/${widget.controller.year}'),
                    ),
                ],
                onChanged: (m) {
                  if (m != null) {
                    setState(() {
                      _month = m;
                      _after = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaxPlanningGroup>(
                initialValue: _group,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Grupo tributário',
                ),
                items: const [
                  DropdownMenuItem(
                    value: TaxPlanningGroup.stock,
                    child: Text('Ações comuns elegíveis à isenção'),
                  ),
                  DropdownMenuItem(
                    value: TaxPlanningGroup.common,
                    child: Text('ETF de renda variável / BDR — comum'),
                  ),
                  DropdownMenuItem(
                    value: TaxPlanningGroup.dayTrade,
                    child: Text('Day trade, exceto FIIs'),
                  ),
                  DropdownMenuItem(
                    value: TaxPlanningGroup.fund,
                    child: Text('FII — operações comuns e day trade'),
                  ),
                ],
                onChanged: (g) {
                  if (g != null) {
                    setState(() {
                      _group = g;
                      _after = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TaxMoneyField(
                label: 'Lucro ou prejuízo líquido adicional',
                controller: _result,
                signed: true,
              ),
              if (_group == TaxPlanningGroup.stock) ...[
                const SizedBox(height: 12),
                TaxMoneyField(
                  label: 'Vendas brutas adicionais de ações',
                  controller: _sales,
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _simulate,
                child: const Text('Simular cenário'),
              ),
            ],
          ),
        ),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      if (_after case final after?)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'DARF principal — antes: ${formatMoney(_before!.darf)} · cenário: ${formatMoney(after.darf)}\n'
            'Imposto após IRRF no mês: ${formatMoney(after.commonTax + after.dayTradeTax + after.fundTax)}\n'
            'Ganho isento em ações no cenário: ${formatMoney(after.exemptGain)}\n'
            'Saldo de prejuízos — comum: ${formatMoney(after.commonLoss)} · '
            'Day trade: ${formatMoney(after.dayTradeLoss)} · FII: ${formatMoney(after.fundLoss)}\n'
            '${after.complete ? 'Histórico até o mês informado.' : 'Cenário parcial: faltam saldos iniciais ou meses anteriores.'}',
          ),
        ),
      const SizedBox(height: 16),
      const Text(
        'Opções para avaliar',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      const Text(
        '• Custos de negociação comprovados integram o custo da compra ou reduzem o resultado da venda.\n'
        '• Prejuízos realizados e documentados podem compensar ganhos no mesmo grupo, no mês ou em meses posteriores. Prejuízo futuro não abate imposto de mês passado.\n'
        '• Ganhos isentos de ações não consomem o saldo de prejuízos; ultrapassar R\$ 20 mil em vendas elegíveis no mês afasta a isenção do ganho do mês inteiro.\n'
        '• O limite de ações é por CPF e mês, somando corretoras; não se aplica a ETFs, BDRs, FIIs nem day trade.\n'
        '• Reduzir imposto não torna uma venda vantajosa: compare custos, risco e estratégia antes de decidir.',
      ),
    ],
  );
}
