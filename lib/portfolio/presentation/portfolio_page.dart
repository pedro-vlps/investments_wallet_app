import 'package:flutter/material.dart';

import '../../app/wallet_theme.dart';
import '../domain/portfolio_totals.dart';
import 'portfolio_controller.dart';
import 'portfolio_summary.dart';
import 'positions_table.dart';

class PortfolioPage extends StatelessWidget {
  const PortfolioPage({
    required this.controller,
    this.detailed = false,
    super.key,
  });
  final PortfolioController controller;
  final bool detailed;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => SelectionArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 700 ? 20 : 40,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.stacked_line_chart_rounded,
                          color: WalletColors.accent,
                          size: 30,
                        ),
                        SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'LOCAL WALLET',
                            style: TextStyle(
                              fontSize: 16,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Tooltip(
                          message:
                              'Carteira armazenada neste dispositivo. Nenhum login necessário.',
                          child: Icon(
                            Icons.storage_rounded,
                            size: 20,
                            color: WalletColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final header = <Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detailed
                                    ? 'Carteira detalhada'
                                    : 'Minha carteira',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                          FilledButton.icon(
                            onPressed:
                                controller.syncing ||
                                    controller.loading ||
                                    controller.positions.isEmpty
                                ? null
                                : controller.synchronize,
                            icon: controller.syncing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.sync_rounded, size: 20),
                            label: Text(
                              controller.syncing
                                  ? 'Atualizando…'
                                  : 'Atualizar cotações',
                            ),
                          ),
                        ];
                        if (constraints.maxWidth < 650) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              header.first,
                              const SizedBox(height: 20),
                              header.last,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: header.first),
                            const SizedBox(width: 24),
                            header.last,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    if (controller.error != null ||
                        controller.notice != null) ...[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          controller.error ?? controller.notice!,
                          style: TextStyle(
                            color: controller.error != null
                                ? WalletColors.loss
                                : WalletColors.accent,
                          ),
                        ),
                      ),
                      if (controller.error != null &&
                          controller.positions.isEmpty)
                        TextButton(
                          onPressed: controller.loading
                              ? null
                              : controller.load,
                          child: const Text('Tentar novamente'),
                        ),
                    ],
                    const SizedBox(height: 24),
                    if (controller.loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(
                            semanticsLabel: 'Carregando carteira local',
                          ),
                        ),
                      )
                    else if (controller.positions.isEmpty &&
                        controller.error == null)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('Nenhum ativo nesta carteira.'),
                      )
                    else if (controller.positions.isNotEmpty) ...[
                      PortfolioSummary(
                        totals: PortfolioTotals(controller.positions),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: WalletColors.surface,
                          border: Border.all(color: WalletColors.border),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text(
                                    'Meus ativos',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${controller.positions.length} ativos · B3',
                                    style: const TextStyle(
                                      color: WalletColors.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            if (detailed)
                              const Padding(
                                padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
                                child: Text(
                                  'Posição = valor do ativo / valor da carteira. Acumulada = '
                                  '(valor atual − custo + dividendos recebidos) / custo. '
                                  'Retorno simples, sem reinvestimento. Clique nos cabeçalhos para ordenar.',
                                  style: TextStyle(
                                    color: WalletColors.muted,
                                    fontSize: 12,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            PositionsTable(
                              key: ValueKey(detailed),
                              positions: controller.positions,
                              detailed: detailed,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
