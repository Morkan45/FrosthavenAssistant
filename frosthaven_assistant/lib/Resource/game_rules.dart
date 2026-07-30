import 'package:collection/collection.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';

import '../Model/character_class.dart';
import '../Model/monster.dart';
import '../services/service_locator.dart';
import 'enums.dart';

class GameRules {
  GameRules._();

  static const int _maxOriginalGloomhavenSoloScenario = 100;

  static bool isObjectiveOrEscort(CharacterClass character) =>
      character.id == 'Escort' || character.id == 'Objective';

  static bool shouldShowAlliesDeck({GameState? gameState, Settings? settings}) {
    final gs = gameState ?? getIt<GameState>();
    if (!(settings ?? getIt<Settings>()).showAmdDeck.value) {
      return false;
    }
    if (gs.showAllyDeck.value) {
      return true;
    }
    if (!gs.allyDeckInOGGloom.value && isOgGloomEdition(gameState: gs)) {
      return false;
    }
    for (final item in gs.currentList) {
      if (item is Monster && item.isAlly) {
        return true;
      }
    }
    return false;
  }

  static bool canExpire(Condition condition) =>
      condition == Condition.strengthen ||
      condition == Condition.stun ||
      condition == Condition.immobilize ||
      condition == Condition.muddle ||
      condition == Condition.invisible ||
      condition == Condition.disarm ||
      condition == Condition.chill ||
      condition == Condition.impair;

  static bool isFrosthavenStyledEdition(
    String edition, {
    GameState? gameState,
  }) {
    final gs = gameState ?? getIt<GameState>();
    final scenario = gs.scenario.value;
    if (edition == 'Solo') {
      if (scenario.contains('#19 ')) {
        return false;
      }
      for (int i = 1; i <= _maxOriginalGloomhavenSoloScenario; i++) {
        if (scenario.contains('#$i ')) {
          return true;
        }
      }
      return false;
    }
    return edition == 'Frosthaven' ||
        edition == 'Buttons and Bugs' ||
        edition == 'Gloomhaven 2nd Edition' ||
        edition == 'Skulls in the Snow' ||
        edition == 'Mercenary Packs';
  }

  static bool summonDoesNotDie(String? ownerId, String id) =>
      ownerId == 'Glacial Torrent' && id == 'Glacier' ||
      ownerId == 'D.O.M.E.' && id == 'Barrier';

  static bool isFrosthavenStyle(
    MonsterModel? monster, {
    GameState? gameState,
    Settings? settings,
  }) {
    final gs = gameState ?? getIt<GameState>();
    final monsterFrosthavenStyledEdition =
        monster != null &&
        isFrosthavenStyledEdition(monster.edition, gameState: gs);
    if (monsterFrosthavenStyledEdition) {
      return true;
    }
    final style = (settings ?? getIt<Settings>()).style.value;
    if (monster != null &&
        style != Style.frosthaven &&
        !monsterFrosthavenStyledEdition) {
      return false;
    }
    return style == Style.frosthaven ||
        style == Style.original &&
            isFrosthavenStyledEdition(gs.currentCampaign.value, gameState: gs);
  }

  static bool isCustomCampaign(String campaign) =>
      campaign == 'Crimson Scales' ||
      campaign == 'Trail of Ashes' ||
      campaign == 'CCUG';

  static int? findNrFromScenarioName(String scenario) {
    String nr = scenario.substring(1);
    for (int i = 0; i < nr.length; i++) {
      if (nr[i] == ' ' || nr[i] == '.') {
        nr = nr.substring(0, i);
        return int.tryParse(nr);
      }
    }
    return null;
  }

  static bool isOgGloomEdition({GameState? gameState}) {
    final gs = gameState ?? getIt<GameState>();
    return !isFrosthavenStyledEdition(gs.currentCampaign.value, gameState: gs);
  }

  static bool hasLootDeck({GameState? gameState, Settings? settings}) {
    final gs = gameState ?? getIt<GameState>();
    var hasLootDeck = !(settings ?? getIt<Settings>()).hideLootDeck.value;
    if (gs.lootDeck.discardPileIsEmpty && gs.lootDeck.drawPileIsEmpty) {
      hasLootDeck = false;
    }
    return hasLootDeck;
  }

  static List<ModifierCard> getFactionCards(String faction) {
    final cards = <ModifierCard>[];
    if (faction == 'Demons') {
      cards.add(ModifierCard(CardType.add, 'Demons-perks/plus1any'));
      cards.add(
        ModifierCard(CardType.add, 'Demons-perks/plus1retaliate1flip'),
      );
      cards.add(ModifierCard(CardType.add, 'Demons-perks/plus0wardallyflip'));
      cards.add(ModifierCard(CardType.add, 'Demons-perks/unique/fuck3'));
    } else if (faction == 'Merchant-Guild') {
      cards.add(ModifierCard(CardType.add, 'Merchant-Guild-perks/plus1curse'));
      cards.add(ModifierCard(CardType.add, 'Merchant-Guild-perks/plus1wound'));
      cards.add(
        ModifierCard(CardType.add, 'Merchant-Guild-perks/plus0heal2flip'),
      );
      cards.add(
        ModifierCard(CardType.add, 'Merchant-Guild-perks/unique/fuck2'),
      );
    } else if (faction == 'Military') {
      cards.add(
        ModifierCard(CardType.add, 'Military-perks/plus1strengthenally'),
      );
      cards.add(ModifierCard(CardType.add, 'Military-perks/plus1shield1flip'));
      cards.add(ModifierCard(CardType.add, 'Military-perks/plus1push2flip'));
      cards.add(ModifierCard(CardType.add, 'Military-perks/unique/fuck1'));
    }
    return cards;
  }

  static bool isCardInAnyCharacterDeck(String gfx, {GameState? gameState}) {
    final gs = gameState ?? getIt<GameState>();
    for (final item in gs.currentList) {
      if (item is Character &&
          !isObjectiveOrEscort(item.characterClass) &&
          item.characterState.modifierDeck.hasCard(gfx)) {
        return true;
      }
    }
    return false;
  }

  static bool hasRetaliate(
    Monster monster,
    MonsterInstance figure, {
    GameState? gameState,
  }) => _monsterHasConditionOnCards(
    monster,
    figure,
    '%retaliate%',
    gameState: gameState,
  );

  static bool hasShield(
    Monster monster,
    MonsterInstance figure, {
    GameState? gameState,
  }) => _monsterHasConditionOnCards(
    monster,
    figure,
    '%shield%',
    gameState: gameState,
  );

  static bool _monsterHasConditionOnCards(
    Monster monster,
    MonsterInstance figure,
    String condition, {
    GameState? gameState,
  }) {
    var hasCondition = false;
    final level = monster.type.levels[monster.level.value];
    if (figure.type == MonsterType.normal) {
      hasCondition =
          level.normal?.attributes.indexWhere((i) => i.contains(condition)) !=
          -1;
    } else if (figure.type == MonsterType.elite) {
      hasCondition =
          level.elite?.attributes.indexWhere((i) => i.contains(condition)) !=
          -1;
    } else if (figure.type == MonsterType.boss) {
      hasCondition =
          level.boss?.attributes.indexWhere((i) => i.contains(condition)) != -1;
    }

    final gs = gameState ?? getIt<GameState>();
    final deck = gs.currentAbilityDecks.firstWhereOrNull(
      (candidate) => candidate.name == monster.type.deck,
    );
    if (deck != null &&
        deck.discardPileIsNotEmpty &&
        monster.turnState.value != TurnsState.notDone) {
      if (deck.discardPileTop.lines.firstWhereOrNull(
            (item) => item.contains(condition),
          ) !=
          null) {
        return true;
      }
    }
    return hasCondition;
  }
}
