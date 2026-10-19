import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReportStorageCard extends StatelessWidget {
  const ReportStorageCard({required this.directory, super.key});
  final String directory;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pasta de dados e backup',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SelectableText(
            directory,
            key: const PageStorageKey('backup-directory-text'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Feche o aplicativo e copie esta pasta inteira para fazer backup. '
            'Para restaurar ou trocar de PC, coloque-a em Documentos com o nome InvestmentsWallet '
            'antes de abrir o app. O banco e os relatórios originais serão reutilizados.',
          ),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: directory));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Caminho copiado.')),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar caminho'),
          ),
        ],
      ),
    ),
  );
}
