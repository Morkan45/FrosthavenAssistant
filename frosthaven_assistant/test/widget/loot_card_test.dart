import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/loot_card_widget.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/Resource/ui_utils.dart';
import 'package:frosthaven_assistant/l10n/app_localizations.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../command/test_helpers.dart';

// ignore_for_file: no-magic-number

Widget _l10nApp(Widget home) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: home,
    );

void main() {
  setUpAll(() async {
    await setUpGame();
  });

  LootCard makeCard({
    int id = 1,
    LootType lootType = LootType.materiel,
    LootBaseValue baseValue = LootBaseValue.one,
    int enhanced = 0,
    String gfx = 'money_1',
    String owner = '',
  }) {
    final card = LootCard(
      id: id,
      lootType: lootType,
      baseValue: baseValue,
      enhanced: enhanced,
      gfx: gfx,
    );
    card.owner = owner;
    return card;
  }

  group('LootCardWidget buildFront', () {
    testWidgets('renders card front image', (WidgetTester tester) async {
      final card = makeCard();
      final originalOnError = FlutterError.onError;
      FlutterError.onError = ignoreOverflowErrors;
      await tester.pumpWidget(
        _l10nApp(Scaffold(body: LootCardFront(card: card, scale: 1.0))),
      );
      FlutterError.onError = originalOnError;
      expect(find.byType(Image), findsAtLeast(1));
    });

    testWidgets('money card shows +1 value text', (WidgetTester tester) async {
      final card = makeCard(lootType: LootType.materiel);
      final originalOnError = FlutterError.onError;
      FlutterError.onError = ignoreOverflowErrors;
      await tester.pumpWidget(
        _l10nApp(Scaffold(body: LootCardFront(card: card, scale: 1.0))),
      );
      FlutterError.onError = originalOnError;
      // materiel type with baseValue.one should show +1
      expect(find.textContaining('+'), findsOneWidget);
    });

    testWidgets('other type card with no enhancement shows no value text',
        (WidgetTester tester) async {
      final card = makeCard(lootType: LootType.other, enhanced: 0);
      final originalOnError = FlutterError.onError;
      FlutterError.onError = ignoreOverflowErrors;
      await tester.pumpWidget(
        _l10nApp(Scaffold(body: LootCardFront(card: card, scale: 1.0))),
      );
      FlutterError.onError = originalOnError;
      // No value text for other type with no enhancement
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('enhanced card shows enhanced text',
        (WidgetTester tester) async {
      final card = makeCard(lootType: LootType.other, enhanced: 3);
      final originalOnError = FlutterError.onError;
      FlutterError.onError = ignoreOverflowErrors;
      await tester.pumpWidget(
        _l10nApp(Scaffold(body: LootCardFront(card: card, scale: 1.0))),
      );
      FlutterError.onError = originalOnError;
      expect(find.textContaining('Enhanced'), findsOneWidget);
    });

    testWidgets('card with gfx containing "1418" shows "1418" text',
        (WidgetTester tester) async {
      final card = makeCard(gfx: 'loot_1418');
      final originalOnError = FlutterError.onError;
      FlutterError.onError = ignoreOverflowErrors;
      await tester.pumpWidget(
        _l10nApp(Scaffold(body: LootCardFront(card: card, scale: 1.0))),
      );
      FlutterError.onError = originalOnError;
      expect(find.text('1418'), findsOneWidget);
    });

    testWidgets('card with gfx containing "1419" shows "1419" text',
        (WidgetTester tester) async {
      final card = makeCard(gfx: 'loot_1419');
      final originalOnError = FlutterError.onError;
      FlutterError.onError = ignoreOverflowErrors;
      await tester.pumpWidget(
        _l10nApp(Scaffold(body: LootCardFront(card: card, scale: 1.0))),
      );
      FlutterError.onError = originalOnError;
      expect(find.text('1419'), findsOneWidget);
    });

    testWidgets('card with non-empty owner shows owner icon',
        (WidgetTester tester) async {
      final card = makeCard(owner: 'Blinkblade');
      final originalOnError = FlutterError.onError;
      FlutterError.onError = ignoreOverflowErrors;
      await tester.pumpWidget(
        _l10nApp(Scaffold(body: LootCardFront(card: card, scale: 1.0))),
      );
      FlutterError.onError = originalOnError;
      // Owner image should be rendered (Image widgets exist)
      expect(find.byType(Image), findsAtLeast(1));
    });

    testWidgets('owner icon renders drop-shadow stack (blur + translate)',
        (WidgetTester tester) async {
      final card = makeCard(owner: 'Blinkblade');
      final originalOnError = FlutterError.onError;
      FlutterError.onError = ignoreOverflowErrors;
      await tester.pumpWidget(
        _l10nApp(Scaffold(body: LootCardFront(card: card, scale: 1.0))),
      );
      FlutterError.onError = originalOnError;
      // The owner icon's drop-shadow layer is a Transform.translate wrapping
      // an ImageFiltered (ImageFilter.blur) wrapping a black-tinted Image.
      // The ImageFiltered is the load-bearing assertion — without it, the
      // shadow would render crisp and the soft-halo effect would be lost.
      expect(find.byType(ImageFiltered), findsOneWidget);
    });

    testWidgets('empty owner does not render drop-shadow stack',
        (WidgetTester tester) async {
      final card = makeCard(owner: '');
      final originalOnError = FlutterError.onError;
      FlutterError.onError = ignoreOverflowErrors;
      await tester.pumpWidget(
        _l10nApp(Scaffold(body: LootCardFront(card: card, scale: 1.0))),
      );
      FlutterError.onError = originalOnError;
      // No owner → no shadow layer
      expect(find.byType(ImageFiltered), findsNothing);
    });
  });

  group('LootCardWidget buildRear', () {
    testWidgets('renders card back image', (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = ignoreOverflowErrors;
      await tester.pumpWidget(
        _l10nApp(Scaffold(body: LootCardRear(scale: 1.0))),
      );
      FlutterError.onError = originalOnError;
      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('LootCardWidget widget', () {
    testWidgets('revealed=true shows front (has Stack)',
        (WidgetTester tester) async {
      final card = makeCard();
      final originalOnError = FlutterError.onError;
      FlutterError.onError = ignoreOverflowErrors;
      await tester.pumpWidget(
        _l10nApp(Scaffold(body: LootCardWidget(card: card, revealed: true))),
      );
      FlutterError.onError = originalOnError;
      // Front has a Stack widget
      expect(find.byType(Stack), findsAtLeast(1));
    });

    testWidgets('revealed=false shows rear (ClipRRect)',
        (WidgetTester tester) async {
      final card = makeCard();
      final originalOnError = FlutterError.onError;
      FlutterError.onError = ignoreOverflowErrors;
      await tester.pumpWidget(
        _l10nApp(Scaffold(body: LootCardWidget(card: card, revealed: false))),
      );
      FlutterError.onError = originalOnError;
      expect(find.byType(ClipRRect), findsOneWidget);
    });
  });

  group('enhanced-text shimmer across the power tiers', () {
    late PowerMode originalMode;
    late bool originalShimmer;

    setUp(() {
      originalMode = getIt<Settings>().powerMode.value;
      originalShimmer = getIt<Settings>().shimmer.value;
      isDimmed.value = false;
    });

    tearDown(() {
      getIt<Settings>().powerMode.value = originalMode;
      getIt<Settings>().shimmer.value = originalShimmer;
      isDimmed.value = false;
    });

    Future<void> pumpEnhanced(WidgetTester tester) async {
      final card = makeCard(lootType: LootType.other, enhanced: 3);
      final originalOnError = FlutterError.onError;
      FlutterError.onError = ignoreOverflowErrors;
      await tester.pumpWidget(
        _l10nApp(Scaffold(body: LootCardFront(card: card, scale: 1.0))),
      );
      FlutterError.onError = originalOnError;
    }

    // The text itself must render in every case — only whether it is animated
    // may vary. A power setting that hid the enhancement level would be a
    // correctness bug, not a battery saving.
    void expectEnhancedTextPresent() {
      expect(find.textContaining('3'), findsAtLeast(1));
    }

    testWidgets('shimmers in normal mode when the user enabled shimmer',
        (WidgetTester tester) async {
      getIt<Settings>().powerMode.value = PowerMode.normal;
      getIt<Settings>().shimmer.value = true;
      await pumpEnhanced(tester);

      expect(find.byType(AnimatedTextKit), findsOneWidget);
      expectEnhancedTextPresent();
    });

    testWidgets('does not shimmer when the user disabled shimmer',
        (WidgetTester tester) async {
      getIt<Settings>().powerMode.value = PowerMode.normal;
      getIt<Settings>().shimmer.value = false;
      await pumpEnhanced(tester);

      expect(find.byType(AnimatedTextKit), findsNothing);
      expectEnhancedTextPresent();
    });

    testWidgets('still shimmers while awake in dim-when-idle mode',
        (WidgetTester tester) async {
      // dimWhenIdle trades convenience, not fidelity: an awake board must look
      // exactly like normal mode.
      getIt<Settings>().powerMode.value = PowerMode.dimWhenIdle;
      getIt<Settings>().shimmer.value = true;
      await pumpEnhanced(tester);

      expect(find.byType(AnimatedTextKit), findsOneWidget);
    });

    testWidgets('does not shimmer once the app has dimmed itself',
        (WidgetTester tester) async {
      getIt<Settings>().powerMode.value = PowerMode.dimWhenIdle;
      getIt<Settings>().shimmer.value = true;
      isDimmed.value = true;
      await pumpEnhanced(tester);

      expect(find.byType(AnimatedTextKit), findsNothing,
          reason: 'a card built while dimmed should not start a ticker at all');
      expectEnhancedTextPresent();
    });

    testWidgets('does not shimmer in reduce-power mode even if shimmer is on',
        (WidgetTester tester) async {
      getIt<Settings>().powerMode.value = PowerMode.reducePower;
      getIt<Settings>().shimmer.value = true;
      await pumpEnhanced(tester);

      expect(find.byType(AnimatedTextKit), findsNothing);
      expectEnhancedTextPresent();
    });
  });
}
