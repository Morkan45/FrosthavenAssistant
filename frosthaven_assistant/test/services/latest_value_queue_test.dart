import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/services/latest_value_queue.dart';

void main() {
  test('writes serially and replaces an older pending value', () async {
    final releaseFirstWrite = Completer<void>();
    final writes = <String>[];
    var activeWrites = 0;
    var maxActiveWrites = 0;

    final queue = LatestValueQueue<String>((value) async {
      activeWrites++;
      maxActiveWrites = activeWrites > maxActiveWrites
          ? activeWrites
          : maxActiveWrites;
      writes.add(value);
      if (writes.length == 1) {
        await releaseFirstWrite.future;
      }
      activeWrites--;
    });

    final firstFlush = queue.schedule('first');
    final secondFlush = queue.schedule('second');
    final thirdFlush = queue.schedule('third');

    expect(writes, ['first']);
    releaseFirstWrite.complete();
    await Future.wait([firstFlush, secondFlush, thirdFlush]);

    expect(writes, ['first', 'third']);
    expect(maxActiveWrites, 1);
  });

  test('flush completes immediately while idle', () async {
    final queue = LatestValueQueue<int>((_) async {});

    await queue.flush();
  });
}
