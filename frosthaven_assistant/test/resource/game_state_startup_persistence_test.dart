import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/network/communication.dart';
import 'package:frosthaven_assistant/services/network/connection.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _gameStateKey = 'gameState';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'corrupt saved game is retained and blocks subsequent persistence',
    () async {
      const corruptPayload = '{"level": 2';
      SharedPreferences.setMockInitialValues({_gameStateKey: corruptPayload});
      final gameState = _gameState();

      await expectLater(gameState.load(), throwsFormatException);
      expect(gameState.level.value, 1);
      var prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_gameStateKey), corruptPayload);

      gameState.save();
      await expectLater(gameState.flushPersistence(), throwsStateError);
      prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_gameStateKey), corruptPayload);
    },
  );

  test(
    'explicit reset removes corrupt saved game and permits loading',
    () async {
      const corruptPayload = '{"level": 2';
      SharedPreferences.setMockInitialValues({_gameStateKey: corruptPayload});
      final gameState = _gameState();

      await expectLater(gameState.load(), throwsFormatException);
      await gameState.resetSavedGame();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(_gameStateKey), isFalse);
      await expectLater(gameState.load(), completion(isTrue));
    },
  );
}

GameState _gameState() => GameState(
  communication: Communication(connection: Connection()),
  settings: Settings(),
)..init();
