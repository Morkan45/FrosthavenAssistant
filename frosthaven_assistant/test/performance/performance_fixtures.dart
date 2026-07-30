// ignore_for_file: no-magic-number

import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_standee_command.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';

enum PerformanceScenario { small, medium, stress }

class PerformanceBudget {
  const PerformanceBudget({
    required this.maxSnapshotBytes,
    required this.maxSerializationP95,
    required this.maxActionP95,
    required this.maxMainListRebuildP95,
  });

  final int maxSnapshotBytes;
  final Duration maxSerializationP95;
  final Duration maxActionP95;
  final Duration maxMainListRebuildP95;
}

class PerformanceFixture {
  const PerformanceFixture({
    required this.scenario,
    required this.characterCount,
    required this.monsterCount,
    required this.standeesPerMonster,
    required this.summonCount,
    required this.budget,
  });

  final PerformanceScenario scenario;
  final int characterCount;
  final int monsterCount;
  final int standeesPerMonster;
  final int summonCount;
  final PerformanceBudget budget;

  String get name => scenario.name;

  void populate(GameState gameState) {
    final characters = _characters.take(characterCount).toList();
    final monsters = _monsters.take(monsterCount).toList();

    for (final character in characters) {
      AddCharacterCommand(character.id, character.edition, null, 4).execute();
    }

    for (final monster in monsters) {
      AddMonsterCommand(monster, 4, false, gameState: gameState).execute();
      for (var standee = 1; standee <= standeesPerMonster; standee++) {
        AddStandeeCommand(
          standee,
          null,
          monster,
          MonsterType.normal,
          false,
          gameState: gameState,
        ).execute();
      }
    }

    for (var index = 0; index < summonCount; index++) {
      final owner = characters[index % characters.length].id;
      final standee = index ~/ characters.length + 1;
      AddStandeeCommand(
        standee,
        SummonData(
          standee,
          'Benchmark Summon ${index + 1}',
          10,
          3,
          3,
          1,
          'BAN banner of courage',
        ),
        owner,
        MonsterType.summon,
        false,
        gameState: gameState,
      ).execute();
    }

    gameState.updateAllUI();
  }
}

const performanceFixtures = [
  PerformanceFixture(
    scenario: PerformanceScenario.small,
    characterCount: 1,
    monsterCount: 1,
    standeesPerMonster: 1,
    summonCount: 0,
    budget: PerformanceBudget(
      maxSnapshotBytes: 128 * 1024,
      maxSerializationP95: Duration(milliseconds: 50),
      maxActionP95: Duration(milliseconds: 100),
      maxMainListRebuildP95: Duration(milliseconds: 200),
    ),
  ),
  PerformanceFixture(
    scenario: PerformanceScenario.medium,
    characterCount: 4,
    monsterCount: 5,
    standeesPerMonster: 2,
    summonCount: 1,
    budget: PerformanceBudget(
      maxSnapshotBytes: 512 * 1024,
      maxSerializationP95: Duration(milliseconds: 75),
      maxActionP95: Duration(milliseconds: 150),
      maxMainListRebuildP95: Duration(milliseconds: 300),
    ),
  ),
  PerformanceFixture(
    scenario: PerformanceScenario.stress,
    characterCount: 4,
    monsterCount: 5,
    standeesPerMonster: 10,
    summonCount: 12,
    budget: PerformanceBudget(
      maxSnapshotBytes: 2 * 1024 * 1024,
      maxSerializationP95: Duration(milliseconds: 150),
      maxActionP95: Duration(milliseconds: 250),
      maxMainListRebuildP95: Duration(milliseconds: 500),
    ),
  ),
];

const _characters = [
  (id: 'Blinkblade', edition: 'Frosthaven'),
  (id: 'Banner Spear', edition: 'Frosthaven'),
  (id: 'Hatchet', edition: 'Jaws of the Lion'),
  (id: 'Demolitionist', edition: 'Jaws of the Lion'),
];

const _monsters = [
  'Zealot',
  'Vermling Raider',
  'Ancient Artillery (FH)',
  'Rat Monstrosity',
  'Black Sludge',
];
