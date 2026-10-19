import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

class WalletStorage {
  const WalletStorage(this.directory);
  final String directory;
  String get databasePath => path.join(directory, 'portfolio.sqlite3');
  String get reportDirectory => path.join(directory, 'reports');

  /// The original support database remains available as a migration backup.
  Future<void> prepare({String? legacyDatabasePath}) => Isolate.run(() {
    Directory(directory).createSync(recursive: true);
    Directory(reportDirectory).createSync(recursive: true);
    if (!File(databasePath).existsSync() &&
        legacyDatabasePath != null &&
        File(legacyDatabasePath).existsSync()) {
      final staging = File('$databasePath.migrating');
      if (staging.existsSync()) staging.deleteSync();
      final legacy = sqlite3.open(legacyDatabasePath, mode: OpenMode.readOnly);
      try {
        legacy.execute('VACUUM INTO ?', [staging.path]);
      } finally {
        legacy.close();
      }
      final check = sqlite3.open(staging.path, mode: OpenMode.readOnly);
      try {
        if (check.select('PRAGMA quick_check').single.values.single != 'ok') {
          throw const FileSystemException(
            'Legacy database integrity check failed',
          );
        }
      } finally {
        check.close();
      }
      staging.renameSync(databasePath);
    }
  });
}
