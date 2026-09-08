import 'package:flutter/material.dart';

import '../services/app_startup_controller.dart';

class StartupRecoveryScreen extends StatelessWidget {
  const StartupRecoveryScreen({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onReset,
  });

  final AppStartupState state;
  final Future<void> Function() onRetry;
  final Future<void> Function() onReset;

  @override
  Widget build(BuildContext context) {
    final isSavedGame = state.failure == AppStartupFailure.gameSave;
    final isSettings = state.failure == AppStartupFailure.settings;
    final title = isSavedGame
        ? 'Saved game could not be loaded'
        : isSettings
        ? 'Settings could not be loaded'
        : 'App startup failed';
    final body = isSavedGame
        ? 'Your stored data has not been changed. You can retry, or reset only the saved game.'
        : isSettings
        ? 'Your stored data has not been changed. Resetting settings also removes named game and character saves stored with those settings.'
        : 'Retry startup. This problem cannot safely be fixed by resetting saved data.';

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Text(body),
                        const SizedBox(height: 24),
                        FilledButton(
                          key: const Key('startup-retry'),
                          onPressed: () => onRetry(),
                          child: const Text('Retry'),
                        ),
                        if (state.canReset) ...[
                          const SizedBox(height: 12),
                          OutlinedButton(
                            key: const Key('startup-reset'),
                            onPressed: () => onReset(),
                            child: Text(
                              isSavedGame
                                  ? 'Reset saved game'
                                  : 'Reset settings and saves',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
