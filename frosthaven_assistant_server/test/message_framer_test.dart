import 'dart:convert';

import 'package:frosthaven_assistant_server/message_framer.dart';
import 'package:test/test.dart';

void main() {
  test('decodes a multibyte payload split at every byte boundary', () {
    const payload = 'Frosthaven å漢字 [EOM] S3nD:';
    final frame = MessageFramer.encode(payload);
    final decoder = MessageFramer();
    final messages = <String>[];

    for (final byte in frame) {
      messages.addAll(decoder.add([byte]));
    }

    expect(messages, [payload]);
  });

  test('decodes multiple frames from one TCP chunk', () {
    final decoder = MessageFramer();
    final bytes = [
      ...MessageFramer.encode('one'),
      ...MessageFramer.encode('two'),
    ];

    expect(decoder.add(bytes), ['one', 'two']);
  });

  test('rejects oversized frames before buffering their payload', () {
    final header = ascii.encode('S3nD:${MessageFramer.maxPayloadBytes + 1}:');

    expect(() => MessageFramer().add(header), throwsFormatException);
  });

  test('rejects malformed prefixes', () {
    expect(
      () => MessageFramer().add(ascii.encode('wrong:1:x')),
      throwsFormatException,
    );
  });
}
