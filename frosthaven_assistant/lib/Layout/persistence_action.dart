import 'package:flutter/material.dart';

/// Owns errors from UI callbacks whose asynchronous result Flutter cannot await.
Future<void> runPersistenceAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (error) {
    debugPrint('Unable to complete saved-state action: $error');
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unable to save'),
        content: const Text(
          'The connection was not started. Check available storage and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
