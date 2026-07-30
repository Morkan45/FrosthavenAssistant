import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../Resource/app_constants.dart';
import '../../../Resource/settings.dart';
import '../../../Resource/state/game_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/network/client.dart';
import '../../../services/network/network.dart';
import '../../../services/service_locator.dart';
import '../../widgets/scrollable_menu_card.dart';
import 'settings_layout.dart';
import 'settings_pages.dart';

class SettingsMenu extends StatefulWidget {
  static const double desktopBreakpoint =
      SettingsLayoutMetrics.desktopBreakpoint;

  const SettingsMenu({
    super.key,
    this.gameState,
    this.network,
    this.client,
    this.settings,
  });

  final GameState? gameState;
  final Network? network;
  final Client? client;
  final Settings? settings;

  @override
  SettingsMenuState createState() => SettingsMenuState();
}

class SettingsMenuState extends State<SettingsMenu> {
  final _sectionScrollController = ScrollController();
  SettingsCategory _selectedCategory = SettingsCategory.display;

  Settings get settings => widget.settings ?? getIt<Settings>();
  GameState get _gameState => widget.gameState ?? getIt<GameState>();
  Network get _network => widget.network ?? getIt<Network>();
  Client get _client => widget.client ?? getIt<Client>();

  @override
  void dispose() {
    _sectionScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final desktop = SettingsLayoutMetrics.useDesktopLayout(size);
    final l10n = AppLocalizations.of(context)!;
    final pages = buildSettingsPages(
      l10n: l10n,
      settings: settings,
      gameState: _gameState,
      network: _network,
      client: _client,
      onLayoutChanged: () => setState(() {}),
    );

    if (!desktop) {
      return _withKeyboardBehavior(
        ScrollableMenuCard(
          maxWidth: kMenuNarrowWidth,
          onClose: settings.saveToDisk,
          child: MobileSettingsBody(title: l10n.menuSettings, pages: pages),
        ),
      );
    }

    final width = SettingsLayoutMetrics.desktopWidth(size);
    final height = SettingsLayoutMetrics.desktopHeight(size);

    return _withKeyboardBehavior(
      ScrollableMenuCard(
        maxWidth: width,
        onClose: settings.saveToDisk,
        child: DesktopSettingsBody(
          title: l10n.menuSettings,
          pages: pages,
          selectedCategory: _selectedCategory,
          scrollController: _sectionScrollController,
          width: width,
          height: height,
          onCategorySelected: (category) {
            setState(() {
              _selectedCategory = category;
            });
            if (_sectionScrollController.hasClients) {
              _sectionScrollController.jumpTo(0);
            }
          },
        ),
      ),
    );
  }

  Widget _withKeyboardBehavior(Widget child) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          settings.saveToDisk();
          Navigator.maybeOf(context)?.maybePop();
        },
      },
      child: Focus(
        autofocus: true,
        skipTraversal: true,
        child: FocusTraversalGroup(child: child),
      ),
    );
  }
}
