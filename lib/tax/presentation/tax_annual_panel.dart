import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'tax_controller.dart';

class TaxAnnualPanel extends StatelessWidget {
  const TaxAnnualPanel({required this.controller, super.key});
  final TaxController controller;

  @override
  Widget build(BuildContext context) {
    final now = controller.clock();
    final inSeason = controller.rules.annualExportAvailable(now);
    final deadline = controller.rules.annualDeadline(now.year);
    final pastYear = controller.year < now.year;
    final assessments = controller.assessments;
    final ready =
        assessments.length == 12 && assessments.every((a) => a.complete);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Declaração de Imposto de Renda',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Text(
          'Ano-calendário ${controller.year} · exercício ${controller.year + 1}',
        ),
        const SizedBox(height: 12),
        const Text(
          'Gere um demonstrativo auxiliar em HTML com os resultados mensais revisados, '
          'prejuízos, IRRF, pagamentos informados e operações B3 para conciliação. '
          'Ele não substitui a declaração completa, não é um arquivo importável no PGD '
          'e não transmite dados à Receita.',
        ),
        const SizedBox(height: 12),
        Text(
          deadline == null
              ? 'Janela de preparação em ${now.year}: de janeiro a junho. Prazo oficial desse exercício ainda não confirmado pelo aplicativo; confira no site da Receita.'
              : 'Janela de preparação em ${now.year}: de janeiro até ${DateFormat('dd/MM/yyyy').format(deadline)}. A entrega oficial tem seu próprio período.',
        ),
        if (!inSeason)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Geração fora da janela anual. Apuração e planejamento continuam disponíveis o ano inteiro.',
            ),
          ),
        if (!pastYear)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Selecione um ano-calendário encerrado para gerar o demonstrativo.',
            ),
          ),
        const SizedBox(height: 12),
        Text(
          ready
              ? 'Os 12 meses e os saldos iniciais foram registrados.'
              : 'Há pendências: o arquivo será identificado como parcial. Meses ausentes não são tratados como meses sem operações.',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: controller.busy || !inSeason || !pastYear
              ? null
              : controller.exportAnnual,
          icon: const Icon(Icons.description_outlined),
          label: const Text('Gerar demonstrativo auxiliar'),
        ),
        if (controller.exportedPath case final file?) ...[
          const SizedBox(height: 12),
          SelectableText('Arquivo salvo: $file'),
          TextButton.icon(
            onPressed: () => Clipboard.setData(ClipboardData(text: file)),
            icon: const Icon(Icons.copy),
            label: const Text('Copiar caminho'),
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          'Conferência obrigatória nos informes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          '• Bens e Direitos: posição e custo fiscal de aquisição em 31/12 dos dois anos, CNPJ, identificação e custódia. Não usar cotação de mercado.\n'
          '• Tesouro Direto: rendimentos e IR retido na fonte conforme informe. A tabela regressiva de 22,5% a 15% depende do prazo; resgates curtos podem ter IOF. Não gerar DARF 6015 para esse rendimento.\n'
          '• ETFs de renda fixa: tributação na fonte conforme o prazo médio da carteira do fundo (25%, 20% ou 15%). Não aplicar a regra dos ETFs de renda variável.\n'
          '• JCP: IRRF de 15% em 2025 e 17,5% a partir de 2026. Use os valores e o ano correto do informe.\n'
          '• Dividendos de empresas brasileiras em 2026: retenção de 10% sobre o total quando a mesma fonte paga mais de R\$ 50 mil no mês ao mesmo residente; há exceções transitórias. A tributação mínima anual de altas rendas, a partir de R\$ 600 mil, exige dados de toda a renda e revisão própria no exercício 2027.\n'
          '• Rendimentos de FIIs: a isenção depende dos requisitos legais do fundo e do cotista; não presumir isenção só pelo ticker.\n'
          '• Proventos de BDRs: possuem tratamento específico de rendimentos do exterior e eventual imposto no exterior. Não entram no cálculo de venda em bolsa.\n'
          '• Obrigatoriedade de declarar depende do conjunto de critérios anuais, não apenas do saldo da carteira. Confira a regra do exercício e os demais rendimentos e bens.',
        ),
      ],
    );
  }
}
