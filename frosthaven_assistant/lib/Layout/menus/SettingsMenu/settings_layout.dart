import 'dart:math';

import 'package:flutter/material.dart';

import '../../../Resource/ui_tokens.dart';

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
  static const double desktopBreakpoint = UiBreakpoints.desktopSettings;
  static const double largeDesktopBreakpoint =
      UiBreakpoints.largeDesktopSettings;
  static const double _desktopTextScale = 1.1;
  static const double _largeDesktopTextScale = 1.2;

  static bool useDesktopLayout(Size size) => size.width >= desktopBreakpoint;

  static bool useLargeDesktopLayout(Size size) =>
      size.width >= largeDesktopBreakpoint;

  static double adaptiveTextScale(Size size) {
    if (useLargeDesktopLayout(size)) return _largeDesktopTextScale;
    if (useDesktopLayout(size)) return _desktopTextScale;
    return 1;
  }

  static double settingsTextScale(Size size, double userMenuScale) =>
      adaptiveTextScale(size) * userMenuScale;

  static double desktopWidth(Size size) => min(
    useLargeDesktopLayout(size)
        ? UiModal.settingsLargeDesktopMaxWidth
        : UiModal.settingsDesktopMaxWidth,
    size.width - UiModal.settingsDesktopHorizontalInset,
  );

  static double desktopHeight(Size size) => max(
    UiModal.settingsDesktopMinHeight,
    min(
      useLargeDesktopLayout(size)
          ? UiModal.settingsLargeDesktopMaxHeight
          : UiModal.settingsDesktopMaxHeight,
      size.height - UiModal.settingsDesktopVerticalInset,
    ),
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
        Text(title, style: UiTypography.title),
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
          Text(title, style: UiTypography.title),
          const SizedBox(height: UiSpacing.sm),
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
                      padding: const EdgeInsets.fromLTRB(
                        UiSpacing.lg,
                        UiSpacing.sm,
                        UiSpacing.md,
                        UiSpacing.xl,
                      ),
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
      padding: const EdgeInsets.only(top: UiSpacing.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: UiSpacing.md),
            child: Text(title, style: UiTypography.title),
          ),
          const Divider(),
          child,
        ],
      ),
    );
  }
}
