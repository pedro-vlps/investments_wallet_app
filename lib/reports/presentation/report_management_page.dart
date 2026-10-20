import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'report_controller.dart';
import 'report_format.dart';
import 'report_issues_list.dart';
import 'report_storage_card.dart';

class ReportManagementPage extends StatelessWidget {
  const ReportManagementPage({
    required this.controller,
    required this.onAdd,
    super.key,
  });
  final ReportController controller;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => ListView(
      key: const PageStorageKey('report-management-scroll'),
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Gerenciar relatórios',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        const Text(
          'Os arquivos originais ficam salvos junto ao banco de dados. '
          'Expanda um relatório para conferir as quantidades importadas e as linhas ignoradas.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar relatórios'),
            ),
            TextButton.icon(
              onPressed: controller.busy ? null : controller.load,
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar lista'),
            ),
          ],
        ),
        if (controller.busy) const LinearProgressIndicator(),
        if (controller.error case final error?)
          Padding(padding: const EdgeInsets.all(12), child: Text(error)),
        if (controller.reports.isEmpty && !controller.busy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Text(
              'Nenhum relatório importado. Adicione seu primeiro arquivo da B3.',
            ),
          ),
        ...controller.reports.map(
          (report) => Card(
            child: ExpansionTile(
              key: PageStorageKey(report.id),
              title: Text(report.name),
              subtitle: Text(
                'Importado em ${DateFormat('dd/MM/yyyy HH:mm').format(report.importedAt.toLocal())} · ${report.assets.length} ativo(s)',
              ),
              childrenPadding: const EdgeInsets.all(16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final asset in report.assets)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      asset.symbol.startsWith('TD') ? asset.name : asset.symbol,
                    ),
                    subtitle: Text(
                      'Compras adicionadas: ${formatReportQuantity(asset.boughtMicros)} · '
                      'Vendas adicionadas: ${formatReportQuantity(asset.soldMicros)} · ${asset.newTrades} operação(ões) nova(s)',
                    ),
                  ),
                if (report.assets.any((asset) => asset.settlementTrades > 0))
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Contém movimentações por data de liquidação. A data do negócio não foi informada neste arquivo.',
                    ),
                  ),
                Text(
                  '${report.duplicateTrades} operação(ões) repetida(s), sem adicionar saldo novamente.',
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'Arquivo original: ${report.relativePath}',
                  key: PageStorageKey('original-${report.id}'),
                ),
                ReportIssuesList(
                  key: PageStorageKey('issues-${report.id}'),
                  issues: report.issues,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ReportStorageCard(directory: controller.dataDirectory),
      ],
    ),
  );
}
