import 'dart:math';

import 'package:flutter/material.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

const double _kMaxListWidth = 740.0;
const double _kReferenceMinBarWidth = 370.0;
const double _kDesktopTargetListWidth = 900.0;
const double _kDesktopMaxColumnWidth = 1400.0;
const double _kMinimumScaleSetting = 0.2;
const double _kMaximumScaleSetting = 3.0;
const double _kFitWidthScaleCurve = 0.3;
const int _kMaxFitColumns = 3;
double get maxWidth =>
    _kMaxListWidth * getIt<Settings>().userScalingMainList.value;
const double referenceWidth = 412.0;

class MainListLayout {
  const MainListLayout({
    required this.availableWidth,
    required this.columnWidth,
    required this.columnCount,
    required this.fitsScreenWidth,
    required this.scale,
  });

  final double availableWidth;
  final double columnWidth;
  final int columnCount;
  final bool fitsScreenWidth;
  final double scale;
}

class MainListLayoutScope extends InheritedWidget {
  const MainListLayoutScope({
    required this.layout,
    required super.child,
    super.key,
  });

  final MainListLayout layout;

  static MainListLayout? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MainListLayoutScope>()?.layout;

  @override
  bool updateShouldNotify(MainListLayoutScope oldWidget) =>
      layout.availableWidth != oldWidget.layout.availableWidth ||
      layout.columnWidth != oldWidget.layout.columnWidth ||
      layout.columnCount != oldWidget.layout.columnCount ||
      layout.fitsScreenWidth != oldWidget.layout.fitsScreenWidth ||
      layout.scale != oldWidget.layout.scale;
}

void setMaxWidth() {}

double getScaleByReference(BuildContext context) {
  return getMainListLayout(context).scale;
}

bool modifiersFitOnBar(BuildContext context, {Settings? settings}) {
  settings = settings ?? getIt<Settings>();
  double screenWidth = MediaQuery.of(context).size.width;
  double referenceMinWidthWithModifiersOnBar = _kReferenceMinBarWidth;
  double barSize = screenWidth / settings.userScalingBars.value;
  if (barSize < referenceMinWidthWithModifiersOnBar) {
    return false;
  }

  return true;
}

double getMainListWidth(BuildContext context) {
  return getMainListLayout(context).columnWidth;
}

int getMainListColumnCount(BuildContext context) {
  return getMainListLayout(context).columnCount;
}

MainListLayout getMainListLayout(BuildContext context, {Settings? settings}) {
  final scopedLayout = MainListLayoutScope.maybeOf(context);
  if (scopedLayout != null) return scopedLayout;

  return calculateMainListLayout(
    MediaQuery.sizeOf(context).width,
    settings: settings,
  );
}

MainListLayout calculateMainListLayout(
  double availableWidth, {
  Settings? settings,
  int? automaticColumnCount,
}) {
  settings ??= getIt<Settings>();
  final safeWidth = max(1.0, availableWidth);

  if (!settings.fitMainListToWidth.value) {
    final scaledMaxWidth = _kMaxListWidth * settings.userScalingMainList.value;
    final columnWidth = min(safeWidth, scaledMaxWidth);
    final columnCount = safeWidth >= columnWidth * 2 ? 2 : 1;
    return MainListLayout(
      availableWidth: safeWidth,
      columnWidth: columnWidth,
      columnCount: columnCount,
      fitsScreenWidth: false,
      scale: columnWidth / referenceWidth,
    );
  }

  final requestedColumns = settings.mainListColumns.value;
  final automaticColumns =
      automaticColumnCount ??
      (safeWidth / _kDesktopTargetListWidth).round().clamp(1, _kMaxFitColumns);
  final columnCount = requestedColumns == 0
      ? automaticColumns
      : requestedColumns.clamp(1, _kMaxFitColumns);
  final maximumColumnWidth = min(
    _kDesktopMaxColumnWidth,
    safeWidth / columnCount,
  );
  final normalizedScale =
      ((settings.userScalingMainList.value - _kMinimumScaleSetting) /
              (_kMaximumScaleSetting - _kMinimumScaleSetting))
          .clamp(0.0, 1.0);
  final scaleFraction =
      _kMinimumScaleSetting +
      (1 - _kMinimumScaleSetting) * pow(normalizedScale, _kFitWidthScaleCurve);
  final columnWidth = maximumColumnWidth * scaleFraction;

  return MainListLayout(
    availableWidth: safeWidth,
    columnWidth: columnWidth,
    columnCount: columnCount,
    fitsScreenWidth: true,
    scale: columnWidth / referenceWidth,
  );
}

extension GlobalPaintBounds on BuildContext {
  // ignore: prefer-match-file-name, file contains scaling utilities and this extension
  Rect? get globalPaintBounds {
    final renderObject =
        findRenderObject(); // Get the RenderObject associated with the widget
    final translation = renderObject
        ?.getTransformTo(null)
        .getTranslation(); // Get its transformation matrix and extract translation

    final ro = renderObject;
    if (translation != null && ro != null) {
      final offset = Offset(
        translation.x,
        translation.y,
      ); // Convert translation to Offset

      return ro.paintBounds.shift(
        offset,
      ); // Shift the paint bounds by the offset
    } else {
      return null;
    }
  }
}
