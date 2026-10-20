import 'package:flutter/material.dart';

import '../../portfolio/domain/asset_category.dart';
import '../domain/report_trade.dart';
import 'report_controller.dart';
import 'report_format.dart';
import 'report_issues_list.dart';
import 'report_storage_card.dart';

class ReportUploadPage extends StatelessWidget {
  const ReportUploadPage({required this.controller, super.key});
  final ReportController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => ListView(
      key: const PageStorageKey('report-upload-scroll'),
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Adicionar relatórios',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        const Text(
          'Exporte Negociação ou Movimentação na Área do Investidor B3 em Excel (.xlsx). '
          'Também aceitamos CSV com as mesmas colunas. Processamento local, sem envio à internet. Máximo de 10 MB.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Compras e vendas de ações, FIIs, ETFs, BDRs e Tesouro Direto. '
          'Transferência - Liquidação com crédito registra compra e com débito registra venda, pela data de liquidação. '
          'Opções, futuros e outros produtos são ignorados. Proventos, '
          'outras transferências e eventos corporativos não alteram a carteira nesta versão. '
          'Importe todo o histórico de compras e vendas; vendas sem saldo serão bloqueadas. '
          'PDF, XLS e relatórios de Posição ainda não são aceitos.',
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: controller.busy ? null : controller.selectFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Selecionar arquivo'),
          ),
        ),
        if (controller.busy)
          const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(
              semanticsLabel: 'Processando relatório',
            ),
          ),
        if (controller.error case final error?)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              semanticsLabel: error,
            ),
          ),
        if (controller.notice case final notice?)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(notice),
          ),
        if (controller.preview case final report?) ...[
          const SizedBox(height: 20),
          Text(
            controller.fileName!,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            '${report.layouts.join(' / ')} · ${report.trades.length} operação(ões) elegível(is)',
          ),
          const SizedBox(height: 8),
          if (report.trades.any(
            (trade) => trade.dateBasis == ReportDateBasis.settlement,
          ))
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Este arquivo usa data de liquidação, não a data do negócio. '
                'Para o mesmo ativo e instituição, use somente negociações ou somente liquidações; '
                'misturar as duas bases é bloqueado para evitar duplicar a carteira. '
                'A data do negócio deve ser conferida para a apuração fiscal.',
              ),
            ),
          const Text(
            'Confira as quantidades compradas e vendidas abaixo. Operações repetidas em arquivos com períodos sobrepostos não serão contadas novamente. '
            'Preços de operações não são cotações atuais; o preço médio não inclui corretagem, taxas ou impostos.',
          ),
          ..._previewAssets(report.trades),
          ReportIssuesList(issues: report.issues),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              key: const ValueKey('confirm-report-import'),
              onPressed: controller.canImport
                  ? controller.importSelected
                  : null,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Importar relatório'),
            ),
          ),
          if (!controller.canImport && !controller.busy)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Selecione a classificação de cada ativo pendente. É necessária ao menos uma operação elegível.',
              ),
            ),
        ],
        const SizedBox(height: 24),
        ReportStorageCard(directory: controller.dataDirectory),
      ],
    ),
  );

  List<Widget> _previewAssets(List<ReportTrade> trades) {
    final grouped = <String, List<ReportTrade>>{};
    for (final trade in trades) {
      grouped.putIfAbsent(trade.symbol, () => []).add(trade);
    }
    return grouped.entries.map((entry) {
      final items = entry.value;
      final category = items.first.category;
      final buys = items
          .where((t) => t.side == TradeSide.buy)
          .fold<int>(0, (sum, t) => sum + t.quantityMicros);
      final sells = items
          .where((t) => t.side == TradeSide.sell)
          .fold<int>(0, (sum, t) => sum + t.quantityMicros);
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                items.first.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'Compras: ${formatReportQuantity(buys)} · Vendas: ${formatReportQuantity(sells)}',
              ),
              if (category != null)
                Text(assetCategoryLabel(category))
              else ...[
                const SizedBox(height: 8),
                const Text(
                  'O código com final 11 não identifica sozinho a classe. Confirme o tipo:',
                ),
                DropdownButtonFormField<int>(
                  key: ValueKey('category-${entry.key}'),
                  initialValue: controller.excludedSymbols.contains(entry.key)
                      ? -1
                      : controller.classifications[entry.key]?.index,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Classificação do ativo',
                  ),
                  items: [
                    for (final option in [
                      AssetCategory.stock,
                      AssetCategory.realEstateFund,
                      AssetCategory.etf,
                    ])
                      DropdownMenuItem(
                        value: option.index,
                        child: Text(assetCategoryLabel(option)),
                      ),
                    const DropdownMenuItem(
                      value: -1,
                      child: Text('Ignorar este ativo'),
                    ),
                  ],
                  onChanged: controller.busy
                      ? null
                      : (value) {
                          if (value != null) {
                            controller.classify(
                              entry.key,
                              value == -1 ? null : AssetCategory.values[value],
                            );
                          }
                        },
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }
}
