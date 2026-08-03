import 'package:collection/collection.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';

import 'game_methods.dart';

enum Style { frosthaven, gloomhaven, original } // ignore: prefer-match-file-name, file contains multiple shared enums

enum Condition {
  stun,
  immobilize,
  disarm,
  wound,
  wound2,
  muddle,
  poison,
  poison2,
  poison3,
  poison4,
  bane,
  brittle,
  chill,
  infect,
  impair,
  rupture,
  plague,
  strengthen,
  invisible,
  regenerate,
  ward,
  dodge,
  safeguard,

  shield,
  retaliate,

  character1,
  character2,
  character3,
  character4;

  static const int _kChar1Index = 0;
  static const int _kChar2Index = 1;
  static const int _kChar3Index = 2;
  static const int _kChar4Index = 3;

  String _getCharacterName(int index) {
    List<Character> characters = GameMethods.getCurrentCharacters();
    characters.sortBy((element) => element.characterClass.name);
    if (characters.length > index) {
      return characters[index].characterClass.name;
    }

    return "Escort"; //some basic
  }

  String getName() {
    //get current characters, sort by name and add to this
    if (this == Condition.character1) {
      return _getCharacterName(_kChar1Index);
    } else if (this == Condition.character2) {
      return _getCharacterName(_kChar2Index);
    } else if (this == Condition.character3) {
      return _getCharacterName(_kChar3Index);
    } else if (this == Condition.character4) {
      return _getCharacterName(_kChar4Index);
    }

    return name;
  }

  @override
  String toString() {
    return index.toString();
  }
}

enum ElementState { full, half, inert }

enum Elements { fire, ice, air, earth, light, dark }

enum RoundState {
  chooseInitiative,
  playTurns,
}

enum ListItemState {
  chooseInitiative, //gray
  waitingTurn, //hopeful
  myTurn, //conditions reminder (above in list is gray)
  doneTurn, //gray, expire conditions
}

enum MonsterType { normal, elite, boss, summon }

enum TurnsState {
  notDone, //if got condition while in this state or from earlier round: remove at end of current
  current, //mark conditions added here to not be removed yet
  done //mark conditions added here to not be removed yet
}

enum NetworkMessage { init, action, undo, redo }

/// Escalating tiers of display power saving. Each tier is a superset of the
/// previous one in how much battery it saves and how much it gets in the way.
enum PowerMode {
  /// Screen held awake at full brightness for as long as the app is open.
  normal,

  /// Screen still held awake — the app never locks and you never lose your
  /// place — but after a period with no input the app dims itself. Sits
  /// between [normal] and [reducePower]: saves real power on OLED without
  /// handing the display over to the system Auto-Lock timer.
  dimWhenIdle,

  /// Releases the wakelock so the system dims and sleeps the display on its
  /// own schedule, and lowers the cost of shadows, image filtering and
  /// looping text animations.
  reducePower,
}
