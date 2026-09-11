import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/line_builder/frosthaven_converter.dart';

void main() {
  test('packaged JSON text never throws during Frosthaven conversion', () {
    final root = Directory('assets/data');
    for (final file in root.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.json')) continue;
      final values = <String>[];
      _collectStrings(jsonDecode(file.readAsStringSync()), values);
      for (final value in values) {
        expect(
          () => FrosthavenConverter.convertLinesToFH([value], false),
          returnsNormally,
          reason: '${file.path}: $value',
        );
      }
    }
  });
}

void _collectStrings(Object? value, List<String> output) {
  if (value is String) {
    output.add(value);
  } else if (value is List) {
    for (final item in value) {
      _collectStrings(item, output);
    }
  } else if (value is Map) {
    for (final item in value.values) {
      _collectStrings(item, output);
    }
  }
}
