import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';

import '../domain/report_trade.dart';

Future<XFile?> pickReportFile() async {
  try {
    return await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'Relatórios B3',
          extensions: ['xlsx', 'csv'],
          uniformTypeIdentifiers: [
            'org.openxmlformats.spreadsheetml.sheet',
            'public.comma-separated-values-text',
          ],
        ),
      ],
    );
  } on MissingPluginException {
    throw const ReportImportException(
      'O seletor de arquivos ainda não foi carregado nesta execução. '
      'Encerre o app e a execução no terminal e inicie novamente pelo run-dev.cmd. '
      'Hot reload e hot restart não carregam novos componentes nativos.',
    );
  } on PlatformException catch (failure) {
    if (failure.code == 'channel-error') {
      throw const ReportImportException(
        'Não foi possível conectar ao seletor de arquivos. '
        'Encerre o app e a execução no terminal e inicie novamente pelo run-dev.cmd. '
        'Hot reload e hot restart não carregam novos componentes nativos.',
      );
    }
    throw const ReportImportException(
      'Não foi possível abrir a janela de seleção de arquivos. '
      'Feche o aplicativo, abra novamente e tente selecionar o relatório.',
    );
  }
}
