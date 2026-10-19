import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'wallet_storage.dart';

Future<WalletStorage> openWalletStorage() async {
  final documents = await getApplicationDocumentsDirectory();
  final support = await getApplicationSupportDirectory();
  var legacyPath = path.join(support.path, 'portfolio.sqlite3');
  if (Platform.isMacOS && !await File(legacyPath).exists()) {
    final userHome = Platform.environment['HOME'];
    if (userHome != null) {
      // Versions before portable storage used the macOS application container.
      legacyPath = path.join(
        userHome,
        'Library',
        'Containers',
        'com.localwallet.investmentsWallet',
        'Data',
        'Library',
        'Application Support',
        'com.localwallet.investmentsWallet',
        'portfolio.sqlite3',
      );
    }
  }
  final storage = WalletStorage(path.join(documents.path, 'InvestmentsWallet'));
  await storage.prepare(legacyDatabasePath: legacyPath);
  return storage;
}
