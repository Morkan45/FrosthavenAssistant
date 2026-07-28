// ignore_for_file: no-magic-number, avoid-late-keyword, avoid-top-level-members-in-tests

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/game_data.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/l10n/app_localizations.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';
import 'package:json_diff/json_diff.dart';
import 'package:shared_preferences/shared_preferences.dart';

late final GameState gameState;
Future<void> setUpGame() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Provide an in-memory SharedPreferences stub so that Settings.saveToDisk()
  // and GameSaveState.saveToDisk() don't throw MissingPluginException.
  SharedPreferences.setMockInitialValues({});

  setupGetIt();
  gameState = getIt<GameState>();
  //initialize game
  gameState.init();
  await getIt<GameData>().loadData("assets/testData/");
  await gameState.load();
}

void checkSaveState() {
  String state = gameState.toString();
  int nrStates = gameState.gameSaveStates.length;
  gameState.save();
  final loaded = gameState.loadFromData(state);
  String newState = gameState.toString();
  assert(loaded);
  assert(gameState.gameSaveStates.length == nrStates + 1);
  assert(newState == state);
}

void checkNoSideEffects(List<String> changedFields, String oldState) {
  final differ = JsonDiffer.fromJson(
    json.decode(oldState),
    json.decode(gameState.toString()),
  );
  DiffNode diff = differ.diff();

  if (kDebugMode) {
    print("for each");
    diff.forEach((s, dn) {
      if (kDebugMode) {
        print(s);
        assert(changedFields.contains(s));
        print(dn.added);
        print(dn.moved);
        print(dn.removed);
        print(dn.changed);
        print(dn.node);
        /*dn.node.forEach((s, dn) {
      print(s);
      print(dn.added);
      print(dn.moved);
      print(dn.path);
      print(dn.removed);
      print(dn.changed);
      print(dn.node);
    });*/
      }
    });
    //}
  }
}

Widget testApp(Widget home) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: const [Locale('en')],
  builder: (context, child) => Material(child: child!),
  home: home,
);

Widget testMaterialApp({required Widget home}) => testApp(home);

FlutterExceptionHandler ignoreOverflowErrors(
  FlutterExceptionHandler? delegate,
) {
  return (FlutterErrorDetails details) {
    final message = details.exceptionAsString();
    final isOverflow = message.startsWith('A RenderFlex overflowed by');
    final isMissingAsset = message.startsWith('Unable to load asset');

    if (isOverflow || isMissingAsset) {
      debugPrint('Ignored expected test layout error: $message');
      return;
    }

    (delegate ?? FlutterError.presentError)(details);
  };
}
