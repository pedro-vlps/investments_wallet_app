import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadPreviewFonts() async {
  if (!const bool.fromEnvironment('CAPTURE_PREVIEW')) return;
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final font in {
    'Segoe UI': 'roboto-regular.ttf',
    'MaterialIcons': 'materialicons-regular.otf',
  }.entries) {
    final loader = FontLoader(font.key);
    final bytes = File(
      '.tools/flutter/bin/cache/artifacts/material_fonts/${font.value}',
    ).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
}
