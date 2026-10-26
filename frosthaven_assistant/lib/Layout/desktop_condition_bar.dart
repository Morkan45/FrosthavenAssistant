import 'package:flutter/material.dart';

import '../Resource/enums.dart';
import '../Resource/game_methods.dart';
import '../Resource/ui_utils.dart';
import '../l10n/app_localizations.dart';
import '../services/service_locator.dart';
import '../services/translation_service.dart';
import 'condition_drag_source.dart';
import 'desktop_condition_scope.dart';
import 'view_models/desktop_conditions_view_model.dart';

/// Quick effects whose horizontal footprint follows the player's chosen size.
class DesktopConditionBar extends StatefulWidget {
  const DesktopConditionBar({
    super.key,
    required this.scale,
    this.effectScale = 2.0,
  });

  final double scale;
  final double effectScale;

  @override
  State<DesktopConditionBar> createState() => _DesktopConditionBarState();
}

class _DesktopConditionBarState extends State<DesktopConditionBar> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controls = DesktopConditionScope.maybeOf(context)!;
    final l10n = AppLocalizations.of(context)!;
    final activeName = controls.activeName;
    final activeLabel = activeName == null
        ? l10n.desktopConditionsHelp
        : l10n.desktopConditionsApplyTo(
            getIt<TranslationService>().t(activeName),
          );
    return Row(
      key: const Key('desktop-condition-bar'),
      children: [
        Tooltip(
          key: const Key('condition-active-turn'),
          message: activeName == null
              ? activeLabel
              : '$activeLabel\n${l10n.desktopConditionsHelp}',
          child: SizedBox(
            width: 24 * widget.scale,
            child: Icon(
              Icons.play_arrow,
              color: activeName == null ? Colors.white54 : Colors.tealAccent,
              size: 20 * widget.scale,
            ),
          ),
        ),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              key: const Key('desktop-condition-scroll'),
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final condition in controls.conditions)
                    _ConditionSource(
                      condition: condition,
                      scale: widget.scale * widget.effectScale,
                      controls: controls,
                      activeLabel: activeLabel,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConditionSource extends StatelessWidget {
  const _ConditionSource({
    required this.condition,
    required this.scale,
    required this.controls,
    required this.activeLabel,
  });

  final Condition condition;
  final double scale;
  final DesktopConditionsViewModel controls;
  final String activeLabel;

  @override
  Widget build(BuildContext context) {
    final name = condition.name.replaceAllMapped(
      RegExp(r'\d+'),
      (match) => ' ${match[0]}',
    );
    final label = getIt<TranslationService>().t(
      '${name[0].toUpperCase()}${name.substring(1)}',
    );
    final suffix =
        GameMethods.isFrosthavenStyle(null) && hasGHVersion(condition.name)
        ? '_fh'
        : '';
    final icon = Image.asset(
      'assets/images/abilities/${condition.name}$suffix.png',
      width: 26 * scale,
      height: 26 * scale,
      filterQuality: FilterQuality.medium,
    );
    final canToggle = controls.canToggleActive(condition);
    final applied = controls.isApplied(condition);
    final size = 40 * scale;
    final button = SizedBox.square(
      dimension: size,
      child: Padding(
        padding: EdgeInsets.all(2 * scale),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: applied ? Colors.teal.withValues(alpha: 0.18) : null,
            border: Border.all(
              color: applied ? Colors.teal : Colors.transparent,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: IconButton(
            key: ValueKey('condition-source-${condition.name}'),
            tooltip: '$label\n$activeLabel',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            isSelected: applied,
            onPressed: canToggle
                ? () => controls.toggleActive(condition)
                : null,
            icon: icon,
            selectedIcon: icon,
          ),
        ),
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: ConditionDragSource(
        condition: condition,
        controls: controls,
        feedback: Material(
          color: controls.isDarkMode
              ? const Color(0xff262222)
              : Theme.of(context).colorScheme.surfaceContainerHigh,
          elevation: 6,
          shape: const CircleBorder(),
          child: SizedBox.square(
            dimension: size,
            child: Center(child: icon),
          ),
        ),
        child: button,
      ),
    );
  }
}
