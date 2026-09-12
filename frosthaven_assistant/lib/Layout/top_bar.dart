import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frosthaven_assistant/Resource/app_constants.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/ui_tokens.dart';
import 'package:frosthaven_assistant/l10n/app_localizations.dart';

import '../Resource/enums.dart';
import '../Resource/ui_utils.dart';
import '../services/service_locator.dart';
import 'element_button.dart';
import 'menus/SettingsMenu/settings_menu.dart';
import 'menus/action_log_menu.dart';
import 'view_models/display_controls_view_model.dart';
import 'widgets/original_ability_card_icon.dart';

enum _TopBarAction {
  zoomOut,
  zoomIn,
  originalValues,
  actionLog,
  settings,
  fullscreen,
}

class TopBar extends StatelessWidget {
  static const double _kMenuIconSize = 24.0;
  static const double _kTitlePaddingLeft = 2.0;
  static const double _kFlexibleHeight = 42.0;
  static const double desktopActionsBreakpoint = UiBreakpoints.desktopActions;

  const TopBar({super.key, this.settings});

  final Settings? settings;

  @override
  Widget build(BuildContext context) {
    final settings = this.settings ?? getIt<Settings>();
    final display = DisplayControlsViewModel(settings: settings);
    return ListenableBuilder(
      listenable: Listenable.merge([
        settings.userScalingBars,
        settings.userScalingMainList,
        settings.noCalculation,
        settings.fullScreen,
      ]),
      builder: (context, child) {
        final userScaling = settings.userScalingBars.value;
        final shadow = textShadow(userScaling);
        final l10n = AppLocalizations.of(context)!;
        final showQuickActions = _showQuickActions(context, userScaling);
        final actionSize = kBarHeight * userScaling;
        final originalLabel = settings.noCalculation.value
            ? l10n.topBarShowCalculatedValues
            : l10n.topBarShowOriginalValues;
        return AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          leading: _TopBarMenuButton(
            tooltip: l10n.topBarOpenMainMenu,
            iconSize: _kMenuIconSize * userScaling,
            shadow: shadow,
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          title: Container(
            padding: EdgeInsets.only(left: _kTitlePaddingLeft * userScaling),
            child: Text(
              "X-haven\nAssistant",
              style: getWhiteShadowStyle(kFontSizeBody * userScaling, shadow),
            ),
          ),
          toolbarHeight: kBarHeight * settings.userScalingBars.value,
          flexibleSpace: ValueListenableBuilder<bool>(
            valueListenable: settings.darkMode,
            builder: (context, value, child) {
              final darkMode = settings.darkMode.value;
              return Container(
                height: _kFlexibleHeight * userScaling,
                decoration: BoxDecoration(
                  color: darkMode ? Colors.black : Colors.transparent,
                  image: DecorationImage(
                    opacity: darkMode ? kDarkModeOpacity : 1,
                    fit: BoxFit.cover,
                    repeat: ImageRepeat.repeatX,
                    image: ResizeImage(
                      AssetImage(
                        darkMode
                            ? 'assets/images/psd/gloomhaven-bar.png'
                            : 'assets/images/psd/frosthaven-bar.png',
                      ),
                      height: quantizeDecodeSize(
                        kBarHeight * settings.userScalingBars.value,
                        quantum: kBarDecodeSizeQuantum,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          actions: [
            if (showQuickActions) ...[
              SizedBox.square(
                dimension: actionSize,
                child: IconButton(
                  key: const Key('top-bar-zoom-out'),
                  tooltip: l10n.topBarZoomOut,
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.zoom_out,
                    size: _kMenuIconSize * userScaling,
                    shadows: [shadow],
                  ),
                  onPressed: display.canZoomOut ? display.zoomOut : null,
                ),
              ),
              SizedBox.square(
                dimension: actionSize,
                child: IconButton(
                  key: const Key('top-bar-zoom-in'),
                  tooltip: l10n.topBarZoomIn,
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.zoom_in,
                    size: _kMenuIconSize * userScaling,
                    shadows: [shadow],
                  ),
                  onPressed: display.canZoomIn ? display.zoomIn : null,
                ),
              ),
              Container(
                width: actionSize,
                height: actionSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: settings.noCalculation.value ? Colors.black45 : null,
                ),
                child: Semantics(
                  toggled: settings.noCalculation.value,
                  child: IconButton(
                    key: const Key('top-bar-original-values'),
                    tooltip: originalLabel,
                    isSelected: settings.noCalculation.value,
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(foregroundColor: Colors.white),
                    icon: OriginalAbilityCardIcon(
                      size: _kMenuIconSize * userScaling,
                    ),
                    onPressed: display.toggleOriginalValues,
                  ),
                ),
              ),
            ],
            Padding(
              padding: EdgeInsets.only(right: 8 * userScaling),
              child: PopupMenuButton<_TopBarAction>(
                key: const Key('desktop-actions-menu'),
                tooltip: l10n.topBarMoreActions,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(actionSize / 2),
                child: SizedBox.square(
                  key: const Key('top-bar-more-actions-target'),
                  dimension: actionSize,
                  child: Center(
                    child: Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: _kMenuIconSize * userScaling,
                    ),
                  ),
                ),
                onSelected: (action) =>
                    _handleAction(context, action, settings),
                itemBuilder: (context) => [
                  if (!showQuickActions) ...[
                    _actionItem(
                      _TopBarAction.zoomOut,
                      Icons.zoom_out,
                      l10n.topBarZoomOut,
                      enabled: display.canZoomOut,
                    ),
                    _actionItem(
                      _TopBarAction.zoomIn,
                      Icons.zoom_in,
                      l10n.topBarZoomIn,
                      enabled: display.canZoomIn,
                    ),
                    CheckedPopupMenuItem<_TopBarAction>(
                      value: _TopBarAction.originalValues,
                      checked: settings.noCalculation.value,
                      child: Text(originalLabel),
                    ),
                    const PopupMenuDivider(),
                  ],
                  _actionItem(
                    _TopBarAction.actionLog,
                    Icons.history,
                    l10n.menuActionLog,
                  ),
                  _actionItem(
                    _TopBarAction.settings,
                    Icons.settings_outlined,
                    l10n.menuSettings,
                  ),
                  _actionItem(
                    _TopBarAction.fullscreen,
                    settings.fullScreen.value
                        ? Icons.fullscreen_exit
                        : Icons.fullscreen,
                    l10n.settingsFullscreen,
                  ),
                ],
              ),
            ),
            ElementButton(
              key: const ValueKey('element-fire'),
              color: const Color.fromARGB(255, 226, 66, 30),
              element: Elements.fire,
              icon: 'assets/images/psd/element-fire.png',
            ),
            ElementButton(
              key: const ValueKey('element-ice'),
              color: const Color.fromARGB(255, 85, 200, 239),
              element: Elements.ice,
              icon: 'assets/images/psd/element-ice.png',
            ),
            ElementButton(
              key: const ValueKey('element-air'),
              color: const Color.fromARGB(255, 152, 176, 181),
              element: Elements.air,
              icon: 'assets/images/psd/element-air.png',
            ),
            ElementButton(
              key: const ValueKey('element-earth'),
              color: const Color.fromARGB(255, 124, 168, 42),
              element: Elements.earth,
              icon: 'assets/images/psd/element-earth.png',
            ),
            ElementButton(
              key: const ValueKey('element-light'),
              color: const Color.fromARGB(255, 236, 166, 15),
              element: Elements.light,
              icon: 'assets/images/psd/element-light.png',
            ),
            ElementButton(
              key: const ValueKey('element-dark'),
              color: const Color.fromARGB(255, 31, 50, 131),
              element: Elements.dark,
              icon: 'assets/images/psd/element-dark.png',
            ),
          ],
        );
      },
    );
  }

  bool _showQuickActions(BuildContext context, double userScaling) {
    final scaledBreakpoint =
        desktopActionsBreakpoint * (userScaling / 1.6).clamp(1.0, 3.0);
    return MediaQuery.sizeOf(context).width >= scaledBreakpoint;
  }

  PopupMenuItem<_TopBarAction> _actionItem(
    _TopBarAction action,
    IconData icon,
    String label, {
    bool enabled = true,
  }) {
    return PopupMenuItem(
      value: action,
      enabled: enabled,
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Flexible(child: Text(label)),
        ],
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    _TopBarAction action,
    Settings settings,
  ) async {
    switch (action) {
      case _TopBarAction.zoomOut:
        DisplayControlsViewModel(settings: settings).zoomOut();
      case _TopBarAction.zoomIn:
        DisplayControlsViewModel(settings: settings).zoomIn();
      case _TopBarAction.originalValues:
        DisplayControlsViewModel(settings: settings).toggleOriginalValues();
      case _TopBarAction.actionLog:
        openDialog(context, const ActionLogMenu());
      case _TopBarAction.settings:
        openDialog(context, const SettingsMenu());
      case _TopBarAction.fullscreen:
        await settings.setFullscreen(!settings.fullScreen.value);
        settings.saveToDisk();
    }
  }
}

class _TopBarMenuButton extends StatefulWidget {
  const _TopBarMenuButton({
    required this.tooltip,
    required this.iconSize,
    required this.shadow,
    required this.onPressed,
  });

  final String tooltip;
  final double iconSize;
  final Shadow shadow;
  final VoidCallback onPressed;

  @override
  State<_TopBarMenuButton> createState() => _TopBarMenuButtonState();
}

class _TopBarMenuButtonState extends State<_TopBarMenuButton> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'Open main menu');
  bool _focused = false;
  bool _hovered = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _activate() => widget.onPressed();

  @override
  Widget build(BuildContext context) {
    final highlighted = _focused || _hovered;
    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        label: widget.tooltip,
        onTap: _activate,
        child: FocusableActionDetector(
          key: const Key('top-bar-main-menu-focus'),
          focusNode: _focusNode,
          mouseCursor: SystemMouseCursors.click,
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (intent) {
                _activate();
                return null;
              },
            ),
          },
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          onShowHoverHighlight: (value) => setState(() => _hovered = value),
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => _focusNode.requestFocus(),
            onPointerUp: (event) {
              // Filter phantom events at (0,0) generated by Flutter on iPadOS.
              if (event.localPosition.dx > 1 || event.localPosition.dy > 1) {
                _activate();
              }
            },
            child: AnimatedContainer(
              duration: UiFocus.transitionDuration,
              decoration: BoxDecoration(
                color: highlighted
                    ? Colors.white.withValues(
                        alpha: UiFocus.hoverOverlayOpacity,
                      )
                    : Colors.transparent,
                border: Border.all(
                  color: _focused ? Colors.white : Colors.transparent,
                  width: UiFocus.outlineWidth,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.menu,
                shadows: [widget.shadow],
                size: widget.iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
