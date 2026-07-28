import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  test('expected layout failures are filtered', () {
    var delegated = false;
    final handler = ignoreOverflowErrors((_) => delegated = true);

    handler(
      FlutterErrorDetails(
        exception: FlutterError('A RenderFlex overflowed by 10 pixels'),
      ),
    );

    expect(delegated, isFalse);
  });

  test('unexpected Flutter failures are delegated', () {
    FlutterErrorDetails? delegated;
    final handler = ignoreOverflowErrors((details) => delegated = details);
    final details = FlutterErrorDetails(exception: StateError('boom'));

    handler(details);

    expect(delegated, same(details));
  });
}
