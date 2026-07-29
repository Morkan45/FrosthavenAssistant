import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/scaling.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    getIt.registerLazySingleton<Settings>(() => Settings());
  });

  tearDownAll(getIt.reset);

  setUp(() {
    final settings = getIt<Settings>();
    settings.userScalingMainList.value = 1;
    settings.fitMainListToWidth.value = false;
    settings.mainListColumns.value = 0;
  });

  group('scaling', () {
    test('setMaxWidth does not throw', () {
      expect(() => setMaxWidth(), returnsNormally);
    });

    testWidgets('getScaleByReference returns positive value', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final scale = getScaleByReference(context);
              expect(scale, greaterThan(0));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getMainListWidth returns positive value', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final width = getMainListWidth(context);
              expect(width, greaterThan(0));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('modifiersFitOnBar returns bool', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final result = modifiersFitOnBar(context);
              expect(result, isA<bool>());
              return const SizedBox();
            },
          ),
        ),
      );
    });

    test('legacy layout keeps two capped columns at 2560', () {
      final layout = calculateMainListLayout(2560);

      expect(layout.fitsScreenWidth, isFalse);
      expect(layout.columnCount, 2);
      expect(layout.columnWidth, 740);
    });

    test('fit-width auto layout centers two target-width columns at 1920', () {
      getIt<Settings>().fitMainListToWidth.value = true;

      final layout = calculateMainListLayout(1920);

      expect(layout.fitsScreenWidth, isTrue);
      expect(layout.columnCount, 2);
      expect(layout.columnWidth, 900);
      expect(layout.contentWidth, 1920);
    });

    test('fit-width auto layout uses three full columns at 2560', () {
      getIt<Settings>().fitMainListToWidth.value = true;

      final layout = calculateMainListLayout(2560);

      expect(layout.columnCount, 3);
      expect(layout.columnWidth, closeTo(853.33, 0.01));
      expect(layout.columnWidth * layout.columnCount, 2560);
      expect(layout.contentWidth, 2560);
    });

    test('fit-width layout respects an explicit column count', () {
      final settings = getIt<Settings>();
      settings.fitMainListToWidth.value = true;
      settings.mainListColumns.value = 1;

      final layout = calculateMainListLayout(2560);

      expect(layout.columnCount, 1);
      expect(layout.columnWidth, 900);
      expect(layout.contentWidth, 2560);
    });

    test('fit-width auto layout preserves one column on compact screens', () {
      getIt<Settings>().fitMainListToWidth.value = true;

      final layout = calculateMainListLayout(800);

      expect(layout.columnCount, 1);
      expect(layout.columnWidth, 800);
    });

    test('three-column fit-width layout responds to main-list scaling', () {
      final settings = getIt<Settings>();
      settings.fitMainListToWidth.value = true;
      settings.userScalingMainList.value = 1.5;

      final layout = calculateMainListLayout(2560, automaticColumnCount: 3);

      expect(layout.columnWidth, closeTo(1280, 0.01));
      expect(layout.contentWidth, closeTo(3840, 0.01));
      expect(layout.scale, closeTo(1280 / referenceWidth, 0.01));
    });
  });
}
