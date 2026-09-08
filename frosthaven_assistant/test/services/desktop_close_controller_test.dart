import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/services/desktop_close_controller.dart';

void main() {
  test('failed close waits for an explicit retry or close anyway', () async {
    var flushes = 0;
    var retries = 0;
    var destroys = 0;
    var fail = true;
    final controller = DesktopCloseController(
      flush: () async {
        flushes++;
        if (fail) throw StateError('disk unavailable');
      },
      retryPersistence: () async => retries++,
      destroy: () async => destroys++,
    );

    expect(await controller.requestClose(), isFalse);
    expect(controller.value, DesktopCloseState.failed);
    expect(destroys, 0);

    fail = false;
    expect(await controller.retryAndClose(), isTrue);
    expect(retries, 1);
    expect(flushes, 2);
    expect(destroys, 1);
  });

  test('close anyway bypasses a persistent failure', () async {
    var destroys = 0;
    final controller = DesktopCloseController(
      flush: () async => throw StateError('disk unavailable'),
      retryPersistence: () async {},
      destroy: () async => destroys++,
    );

    await controller.requestClose();
    await controller.closeAnyway();

    expect(controller.value, DesktopCloseState.closed);
    expect(destroys, 1);
  });
}
