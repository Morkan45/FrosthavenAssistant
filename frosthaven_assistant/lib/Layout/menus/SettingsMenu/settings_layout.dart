import 'dart:math';

import 'package:flutter/material.dart';

import '../../../Resource/app_constants.dart';

enum SettingsCategory { display, gameplay, content, network, advanced }

class SettingsPage {
  const SettingsPage({
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

class SettingsLayoutMetrics {
  static const double desktopBreakpoint = 1000;
  static const double _desktopMaxWidth = 920;
  static const double _desktopMaxHeight = 640;
  static const double _desktopHorizontalInset = 72;
  static const double _desktopVerticalInset = 96;
  static const double _desktopMinHeight = 280;

  static bool useDesktopLayout(Size size) => size.width >= desktopBreakpoint;

  static double desktopWidth(Size size) =>
      min(_desktopMaxWidth, size.width - _desktopHorizontalInset);

  static double desktopHeight(Size size) => max(
    _desktopMinHeight,
    min(_desktopMaxHeight, size.height - _desktopVerticalInset),
  );
}

class MobileSettingsBody extends StatelessWidget {
  const MobileSettingsBody({
    super.key,
    required this.title,
    required this.pages,
  });

  final String title;
  final List<SettingsPage> pages;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: kTitleStyle),
        for (final page in pages)
          _MobileSettingsSection(
            key: Key('settings-section-${page.category.name}'),
            title: page.label,
            child: page.child,
          ),
      ],
    );
  }
}

class DesktopSettingsBody extends StatelessWidget {
  const DesktopSettingsBody({
    super.key,
    required this.title,
    required this.pages,
    required this.selectedCategory,
    required this.scrollController,
    required this.width,
    required this.height,
    required this.onCategorySelected,
  });

  final String title;
  final List<SettingsPage> pages;
  final SettingsCategory selectedCategory;
  final ScrollController scrollController;
  final double width;
  final double height;
  final ValueChanged<SettingsCategory> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = pages.indexWhere(
      (page) => page.category == selectedCategory,
    );

    return SizedBox(
      key: const Key('desktop-settings-layout'),
      width: width,
      height: height,
      child: Column(
        children: [
          Text(title, style: kTitleStyle),
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
                  onDestinationSelected: (index) =>
                      onCategorySelected(pages[index].category),
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
                    controller: scrollController,
                    child: SingleChildScrollView(
                      key: Key(
                        'settings-section-${pages[selectedIndex].category.name}',
                      ),
                      controller: scrollController,
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
    );
  }
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
