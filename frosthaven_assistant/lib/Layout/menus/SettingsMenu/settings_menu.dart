import 'dart:math';

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
import 'settings_advanced_section.dart';
import 'settings_content_section.dart';
import 'settings_display_section.dart';
import 'settings_gameplay_section.dart';
import 'settings_network_section.dart';

enum SettingsCategory { display, gameplay, content, network, advanced }

class SettingsMenu extends StatefulWidget {
  static const double desktopBreakpoint = 1000;
  static const double _desktopMaxWidth = 920;
  static const double _desktopMaxHeight = 640;
  static const double _desktopHorizontalInset = 72;
  static const double _desktopVerticalInset = 96;

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
    final desktop = size.width >= SettingsMenu.desktopBreakpoint;
    final l10n = AppLocalizations.of(context)!;
    final pages = _pages(l10n);

    if (!desktop) {
      return _withKeyboardBehavior(
        ScrollableMenuCard(
          maxWidth: kMenuNarrowWidth,
          onClose: settings.saveToDisk,
          child: Column(
            children: [
              Text(l10n.menuSettings, style: kTitleStyle),
              for (final page in pages)
                _MobileSettingsSection(
                  key: Key('settings-section-${page.category.name}'),
                  title: page.label,
                  child: page.child,
                ),
            ],
          ),
        ),
      );
    }

    final width = min(
      SettingsMenu._desktopMaxWidth,
      size.width - SettingsMenu._desktopHorizontalInset,
    );
    final height = max(
      280.0,
      min(
        SettingsMenu._desktopMaxHeight,
        size.height - SettingsMenu._desktopVerticalInset,
      ),
    );
    final selectedIndex = pages.indexWhere(
      (page) => page.category == _selectedCategory,
    );

    return _withKeyboardBehavior(
      ScrollableMenuCard(
        maxWidth: width,
        onClose: settings.saveToDisk,
        child: SizedBox(
          key: const Key('desktop-settings-layout'),
          width: width,
          height: height,
          child: Column(
            children: [
              Text(l10n.menuSettings, style: kTitleStyle),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NavigationRail(
                      key: const Key('settings-category-navigation'),
                      backgroundColor: Colors.transparent,
                      selectedIndex: selectedIndex,
                      labelType: NavigationRailLabelType.all,
                      onDestinationSelected: (index) {
                        setState(() {
                          _selectedCategory = pages[index].category;
                        });
                        if (_sectionScrollController.hasClients) {
                          _sectionScrollController.jumpTo(0);
                        }
                      },
                      destinations: [
                        for (final page in pages)
                          NavigationRailDestination(
                            icon: Icon(page.icon),
                            label: Text(page.label),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: Scrollbar(
                        controller: _sectionScrollController,
                        child: SingleChildScrollView(
                          key: Key(
                            'settings-section-${pages[selectedIndex].category.name}',
                          ),
                          controller: _sectionScrollController,
                          padding: const EdgeInsets.fromLTRB(24, 8, 16, 48),
                          child: pages[selectedIndex].child,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

  List<_SettingsPage> _pages(AppLocalizations l10n) => [
    _SettingsPage(
      category: SettingsCategory.display,
      label: l10n.settingsCategoryDisplay,
      icon: Icons.monitor_outlined,
      child: SettingsDisplaySection(
        settings: settings,
        gameState: _gameState,
        onLayoutChanged: () => setState(() {}),
      ),
    ),
    _SettingsPage(
      category: SettingsCategory.gameplay,
      label: l10n.settingsCategoryGameplay,
      icon: Icons.tune,
      child: SettingsGameplaySection(settings: settings, gameState: _gameState),
    ),
    _SettingsPage(
      category: SettingsCategory.content,
      label: l10n.settingsCategoryContent,
      icon: Icons.view_list_outlined,
      child: SettingsContentSection(settings: settings, gameState: _gameState),
    ),
    _SettingsPage(
      category: SettingsCategory.network,
      label: l10n.settingsCategoryNetwork,
      icon: Icons.lan_outlined,
      child: SettingsNetworkSection(
        settings: settings,
        network: _network,
        client: _client,
      ),
    ),
    _SettingsPage(
      category: SettingsCategory.advanced,
      label: l10n.settingsCategoryAdvanced,
      icon: Icons.settings_suggest_outlined,
      child: SettingsAdvancedSection(gameState: _gameState),
    ),
  ];
}

class _SettingsPage {
  const _SettingsPage({
    required this.category,
    required this.label,
    required this.icon,
    required this.child,
  });

  final SettingsCategory category;
  final String label;
  final IconData icon;
  final Widget child;
}

class _MobileSettingsSection extends StatelessWidget {
  const _MobileSettingsSection({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(title, style: kTitleStyle),
          ),
          const Divider(),
          child,
        ],
      ),
    );
  }
}
