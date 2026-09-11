import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'supported ARB files match the English key and placeholder contract',
    () {
      final directory = Directory('lib/l10n');
      final english =
          jsonDecode(File('${directory.path}/app_en.arb').readAsStringSync())
              as Map<String, dynamic>;
      final expectedKeys = english.keys
          .where((key) => key != '@@locale')
          .toSet();

      for (final file in directory.listSync().whereType<File>()) {
        if (!file.path.endsWith('.arb') || file.path.endsWith('app_en.arb'))
          continue;
        final locale =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        expect(
          locale.keys.where((key) => key != '@@locale').toSet(),
          expectedKeys,
          reason: '${file.path} must match app_en.arb',
        );
      }
    },
  );
}
