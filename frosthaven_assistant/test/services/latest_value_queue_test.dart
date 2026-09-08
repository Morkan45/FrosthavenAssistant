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

  test('schedule and settled flush expose a write failure', () async {
    final error = StateError('disk full');
    final queue = LatestValueQueue<int>((_) async => throw error);

    await expectLater(queue.schedule(1), throwsA(same(error)));
    expect(queue.status.value.writing, isFalse);
    expect(queue.status.value.error, same(error));
    await expectLater(queue.flush(), throwsA(same(error)));
  });

  test(
    'ignored schedule failure is handled and remains available to flush',
    () async {
      final error = StateError('background failure');
      final queue = LatestValueQueue<int>((_) async => throw error);

      queue.schedule(1);
      await Future<void>.delayed(Duration.zero);

      await expectLater(queue.flush(), throwsA(same(error)));
    },
  );

  test('a later successful write clears failure and status', () async {
    var fail = true;
    final queue = LatestValueQueue<int>((_) async {
      if (fail) throw StateError('first failure');
    });

    await expectLater(queue.schedule(1), throwsStateError);
    fail = false;
    await queue.schedule(2);

    await queue.flush();
    expect(queue.status.value.hasError, isFalse);
  });

  test('retryLatest retains and retries a failed value', () async {
    final writes = <int>[];
    var fail = true;
    final queue = LatestValueQueue<int>((value) async {
      writes.add(value);
      if (fail) throw StateError('failure');
    });

    await expectLater(queue.schedule(7), throwsStateError);
    fail = false;
    await queue.retryLatest();

    expect(writes, [7, 7]);
    expect(queue.status.value.hasError, isFalse);
  });

  test(
    'retryLatest starts a new drain after a synchronous writer failure',
    () async {
      var fail = true;
      final writes = <int>[];
      final queue = LatestValueQueue<int>((value) {
        writes.add(value);
        if (fail) throw StateError('synchronous failure');
        return Future<void>.value();
      });

      await expectLater(queue.schedule(4), throwsStateError);
      fail = false;
      await queue.retryLatest();

      expect(writes, [4, 4]);
      await queue.flush();
    },
  );

  test('status listener can schedule while a drain starts', () async {
    final writes = <int>[];
    final queue = LatestValueQueue<int>((value) async => writes.add(value));
    var scheduledFromListener = false;
    queue.status.addListener(() {
      if (queue.status.value.writing && !scheduledFromListener) {
        scheduledFromListener = true;
        queue.schedule(2);
      }
    });

    await queue.schedule(1);

    expect(writes, [2]);
  });

  test(
    'synchronous throwing writer can schedule a newer value reentrantly',
    () async {
      late LatestValueQueue<int> queue;
      final writes = <int>[];
      queue = LatestValueQueue<int>((value) {
        writes.add(value);
        if (value == 1) {
          queue.schedule(2);
          throw StateError('sync failure');
        }
        return Future<void>.value();
      });

      await expectLater(queue.schedule(1), throwsStateError);

      expect(writes, [1, 2]);
      expect(queue.status.value.hasError, isFalse);
      await queue.flush();
    },
  );
}
