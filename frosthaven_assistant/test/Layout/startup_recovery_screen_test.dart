import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/startup_recovery_screen.dart';
import 'package:frosthaven_assistant/services/app_startup_controller.dart';

void main() {
  testWidgets('corrupt saved game offers retry and explicit reset', (
    tester,
  ) async {
    var retried = 0;
    var reset = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StartupRecoveryScreen(
          state: AppStartupState.recoverableError(
            failure: AppStartupFailure.gameSave,
            error: const FormatException(),
          ),
          onRetry: () async => retried++,
          onReset: () async => reset++,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('startup-retry')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('startup-reset')));
    await tester.pump();
    expect(retried, 1);
    expect(reset, 1);
    expect(find.text('Reset saved game'), findsOneWidget);
  });

  testWidgets('asset failure cannot reset stored data', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StartupRecoveryScreen(
          state: AppStartupState.recoverableError(
            failure: AppStartupFailure.other,
            error: StateError('asset'),
          ),
          onRetry: () async {},
          onReset: () async {},
        ),
      ),
    );

    expect(find.byKey(const Key('startup-reset')), findsNothing);
  });
}
