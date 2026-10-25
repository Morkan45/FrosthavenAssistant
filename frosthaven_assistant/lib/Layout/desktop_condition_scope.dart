import 'package:flutter/material.dart';

import 'view_models/desktop_conditions_view_model.dart';

class DesktopConditionScope
    extends InheritedNotifier<DesktopConditionsViewModel> {
  const DesktopConditionScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static DesktopConditionsViewModel? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DesktopConditionScope>()
      ?.notifier;

  static bool supportsPlatform(BuildContext context) =>
      switch (Theme.of(context).platform) {
        TargetPlatform.windows ||
        TargetPlatform.macOS ||
        TargetPlatform.linux ||
        // Debug desktop builds use Flutter's Fuchsia platform override.
        TargetPlatform.fuchsia => true,
        TargetPlatform.android || TargetPlatform.iOS => false,
      };
}
