import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/tax_sources.dart';
import '../domain/tax_rules.dart';
import 'tax_controller.dart';

class TaxRulesCard extends StatelessWidget {
  const TaxRulesCard({required this.controller, super.key});
  final TaxController controller;

  @override
  Widget build(BuildContext context) {
    final rules = controller.rules;
    final pending = rules.changedSources.isNotEmpty;
    final stale = rules.needsCheck(controller.clock());
    final warning =
        rules.online == false || pending || stale || rules.problem != null;
    final date = DateFormat('dd/MM/yyyy');
    final message = rules.online == false
        ? 'Sem acesso às fontes oficiais. As regras de impostos podem estar desatualizadas.'
        : pending
        ? 'Mudança detectada em fonte oficial. As fórmulas precisam de revisão antes de serem consideradas atuais.'
        : rules.problem ??
              (stale
                  ? 'Checagem das fontes pendente. As regras podem estar desatualizadas.'
                  : 'Fontes consultadas sem mudança em relação à referência desta versão.');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  warning ? Icons.flag_outlined : Icons.fact_check_outlined,
                  color: warning ? Colors.amber : null,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(message)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Regras: ${TaxRules.revision} · referência consultada em ${date.format(TaxRules.reviewedAt)}',
            ),
            Text(
              'Última consulta completa: ${rules.checkedAt == null ? 'não realizada' : date.format(rules.checkedAt!)}',
            ),
            const Text(
              'Checagem automática ao abrir e, no máximo, a cada 6 meses; '
              'nova tentativa enquanto o app estiver aberto. A consulta detecta alterações nas páginas monitoradas, '
              'mas não interpreta leis nem altera alíquotas automaticamente. Novas regras exigem atualização revisada do aplicativo.',
            ),
            if (pending) Text('Revisar: ${rules.changedSources.join(', ')}'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: controller.checking
                  ? null
                  : () => controller.checkRules(force: true),
              icon: controller.checking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(
                controller.checking
                    ? 'Consultando fontes…'
                    : 'Checar regras agora',
              ),
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Fontes oficiais monitoradas'),
              children: [
                for (final source in taxSources)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(source.title),
                              const SizedBox(height: 4),
                              SelectionArea(
                                child: Text(
                                  source.url,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copiar endereço da fonte',
                          icon: const Icon(Icons.copy),
                          onPressed: () => Clipboard.setData(
                            ClipboardData(text: source.url),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
