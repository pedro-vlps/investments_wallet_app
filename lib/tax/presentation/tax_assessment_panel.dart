import 'package:flutter/material.dart';

import '../../financial_display/number_format.dart';
import '../domain/tax_assessment.dart';
import 'tax_controller.dart';
import 'tax_entry_dialog.dart';

class TaxAssessmentPanel extends StatelessWidget {
  const TaxAssessmentPanel({required this.controller, super.key});
  final TaxController controller;

  @override
  Widget build(BuildContext context) {
    final assessments = controller.assessments;
    final pending = assessments.fold<int>(
      0,
      (sum, a) => sum + a.unpaidPrincipal,
    );
    final opening = controller.data.opening;
    final expectedMonths = controller.year == controller.clock().year
        ? controller.clock().month
        : 12;
    final missingMonths = [
      for (var month = 1; month <= expectedMonths; month++)
        if (!controller.data.months.any((entry) => entry.month == month)) month,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${assessments.any((a) => !a.complete) ? 'Cálculo parcial — ' : ''}Principal pendente nos meses registrados: ${formatMoney(pending)}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        const Text(
          'Apuração assistida para pessoa física residente no Brasil. '
          'Os relatórios B3 servem para conciliação: não incluem todos os custos, '
          'IRRF ou eventos necessários para calcular imposto automaticamente. '
          'Confirme os resultados mensais em todas as suas corretoras.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: controller.busy
                  ? null
                  : () => showDialog<void>(
                      context: context,
                      builder: (_) =>
                          TaxEntryDialog(controller: controller, opening: true),
                    ),
              child: Text(
                opening == null
                    ? 'Informar saldos iniciais'
                    : 'Editar saldos iniciais',
              ),
            ),
            FilledButton.icon(
              onPressed: controller.busy
                  ? null
                  : () => showDialog<void>(
                      context: context,
                      builder: (_) => TaxEntryDialog(controller: controller),
                    ),
              icon: const Icon(Icons.add),
              label: const Text('Registrar mês'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (opening == null)
          const Text(
            'Pendente: confirme os saldos de janeiro para habilitar um histórico completo.',
          )
        else
          Text(
            'Prejuízos iniciais — comum: ${formatMoney(opening.commonLoss)} · '
            'Day trade: ${formatMoney(opening.dayTradeLoss)} · FII: ${formatMoney(opening.fundLoss)}',
          ),
        const SizedBox(height: 12),
        if (missingMonths.isNotEmpty)
          Text(
            'Meses ainda não revisados: ${missingMonths.join(', ')}. Não estão incluídos no total acima.',
          ),
        if (assessments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Nenhuma apuração registrada. Registre também meses sem operações para confirmar o histórico.',
            ),
          ),
        for (final assessment in assessments) _monthCard(context, assessment),
        const SizedBox(height: 12),
        const Text(
          'DARF 6015: vencimento no último dia útil do mês seguinte à operação. '
          'Confirme o dia na Agenda Tributária da Receita. Valores inferiores a R\$ 10 '
          'acumulam com o mesmo código até atingir o mínimo. O registro de pagamento '
          'é manual; juros e multa por atraso devem ser calculados no Sicalc.',
        ),
        const SizedBox(height: 12),
        Text(
          '${controller.trades.where((t) => t.date.year == controller.year).length} '
          'operações importadas neste ano, disponíveis para conciliação no demonstrativo anual.',
        ),
      ],
    );
  }

  Widget _monthCard(BuildContext context, TaxAssessment a) => Card(
    child: ExpansionTile(
      title: Text(
        '${a.input.month.toString().padLeft(2, '0')}/${a.input.year} · DARF principal ${formatMoney(a.darf)}',
      ),
      subtitle: Text(
        a.complete
            ? 'Histórico revisado até este mês'
            : 'Cálculo parcial: faltam saldos ou meses anteriores',
      ),
      childrenPadding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Ganho isento em ações: ${formatMoney(a.exemptGain)}\n'
            'Imposto após IRRF — comum: ${formatMoney(a.commonTax)} · '
            'Day trade: ${formatMoney(a.dayTradeTax)} · FII: ${formatMoney(a.fundTax)}\n'
            'Prejuízo a compensar — comum: ${formatMoney(a.commonLoss)} · '
            'Day trade: ${formatMoney(a.dayTradeLoss)} · FII: ${formatMoney(a.fundLoss)}\n'
            'IRRF a compensar no ano — comum: ${formatMoney(a.commonCredit)} · '
            'Day trade: ${formatMoney(a.dayTradeCredit)} · FII: ${formatMoney(a.fundCredit)}\n'
            'DARF abaixo do mínimo a transportar: ${formatMoney(a.smallDarf)}\n'
            'Principal informado como pago: ${formatMoney(a.input.paid)}\n'
            'Principal pendente: ${formatMoney(a.unpaidPrincipal)}',
          ),
        ),
        if (a.input.notes.isNotEmpty)
          Align(alignment: Alignment.centerLeft, child: Text(a.input.notes)),
        if (a.input.paid > a.darf)
          const Text(
            'Pagamento informado acima do principal apurado: revise a alocação e eventuais juros/multas.',
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: controller.busy
                ? null
                : () => showDialog<void>(
                    context: context,
                    builder: (_) =>
                        TaxEntryDialog(controller: controller, month: a.input),
                  ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar mês'),
          ),
        ),
      ],
    ),
  );
}
