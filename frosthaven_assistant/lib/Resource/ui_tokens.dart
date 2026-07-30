import 'package:flutter/material.dart';

class UiSpacing {
  UiSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double section = 18;
  static const double menuTop = 20;
  static const double lg = 24;
  static const double xl = 48;
}

class UiTargetSize {
  UiTargetSize._();

  static const double compact = 40;
  static const double closeButtonWidth = 100;
}

class UiTypography {
  UiTypography._();

  static const double smallSize = 14;
  static const double bodySize = 16;
  static const double titleSize = 18;
  static const double buttonLabelSize = 20;
  static const double headingSize = 24;
  static const double toastSize = 28;

  static const TextStyle small = TextStyle(
    fontSize: smallSize,
    color: Colors.grey,
  );
  static const TextStyle body = TextStyle(fontSize: bodySize);
  static const TextStyle bodyBlack = TextStyle(
    fontSize: bodySize,
    color: Colors.black,
  );
  static const TextStyle title = TextStyle(fontSize: titleSize);
  static const TextStyle buttonLabel = TextStyle(fontSize: buttonLabelSize);
  static const TextStyle heading = TextStyle(fontSize: headingSize);
}

class UiFocus {
  UiFocus._();

  static const double outlineWidth = 2;
  static const double hoverOverlayOpacity = 0.12;
  static const Duration transitionDuration = Duration(milliseconds: 100);

  static Color outlineColor(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
}

class UiRadii {
  UiRadii._();

  static const double card = 4;
  static const double deckStack = 5;
  static const double gameCard = 8;
}

class UiModal {
  UiModal._();

  static const double narrowWidth = 300;
  static const double standardWidth = 400;
  static const double settingsDesktopMaxWidth = 920;
  static const double settingsDesktopMaxHeight = 640;
  static const double settingsDesktopHorizontalInset = 72;
  static const double settingsDesktopVerticalInset = 96;
  static const double settingsDesktopMinHeight = 280;
  static const double closeButtonSpacing = 34;
}

class UiBreakpoints {
  UiBreakpoints._();

  static const double desktopActions = 900;
  static const double desktopSettings = 1000;
  static const double phoneMaxDimension = 600;
  static const double largeTabletMinDimension = 1200;
}
