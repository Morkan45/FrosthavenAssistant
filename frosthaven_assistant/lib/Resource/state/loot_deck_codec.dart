part of 'game_state.dart';

class LootDeckCodec {
  LootDeckCodec._();

  static void restore(LootDeck deck, Map<String, dynamic> lootDeckData) {
    deck._hasCard1418 = lootDeckData['1418'] as bool;
    deck._hasCard1419 = lootDeckData['1419'] as bool;

    deck._addedCards = lootDeckData.containsKey('addedCards')
        ? List<int>.from(lootDeckData['addedCards'] as List)
        : [0, 0, 0, 0, 0, 0, 0, 0, 0];
    deck._enhancements = lootDeckData.containsKey('enhancements')
        ? Map<String, int>.from(lootDeckData['enhancements'] as Map)
        : {};

    deck._initPools();

    final drawCards = <LootCard>[];
    final discardCards = <LootCard>[];
    int fallbackId = 0;
    for (final item in lootDeckData['drawPile'] as List) {
      if (item.containsKey('id')) fallbackId = item['id'] as int;
      drawCards.add(_cardFromJson(item as Map, fallbackId));
    }
    for (final item in lootDeckData['discardPile'] as List) {
      if (item.containsKey('id')) fallbackId = item['id'] as int;
      discardCards.add(_cardFromJson(item as Map, fallbackId));
    }

    deck._drawPile.clear();
    deck._discardPile.clear();
    deck._drawPile.setList(drawCards);
    deck._discardPile.setList(discardCards);
  }

  static Map<String, dynamic> serialize(LootDeck deck) => {
    'drawPile': deck._drawPile.getList().map((card) => card.toJson()).toList(),
    'discardPile': deck._discardPile
        .getList()
        .map((card) => card.toJson())
        .toList(),
    'addedCards': deck._addedCards,
    'enhancements': deck._enhancements,
    '1418': deck._hasCard1418,
    '1419': deck._hasCard1419,
  };

  static LootCard _cardFromJson(Map<dynamic, dynamic> item, int fallbackId) {
    final gfx = item['gfx'] as String;
    final owner = item.containsKey('owner') ? item['owner'] as String : '';
    final id = item.containsKey('id') ? item['id'] as int : fallbackId;

    var enhanced = 0;
    if (item['enhanced'] is bool) {
      enhanced = (item['enhanced'] as bool) ? 1 : 0;
    } else if (item['enhanced'] is num) {
      enhanced = (item['enhanced'] as num).toInt();
    }

    final baseIndex = item['baseValue'] is int ? item['baseValue'] as int : 0;
    final lootTypeIndex = item['lootType'] is int ? item['lootType'] as int : 0;
    final baseValue = baseIndex >= 0 && baseIndex < LootBaseValue.values.length
        ? LootBaseValue.values[baseIndex]
        : LootBaseValue.values.first;
    final lootType =
        lootTypeIndex >= 0 && lootTypeIndex < LootType.values.length
        ? LootType.values[lootTypeIndex]
        : LootType.values.first;

    return LootCard(
      id: id,
      gfx: gfx,
      enhanced: enhanced,
      baseValue: baseValue,
      lootType: lootType,
    )..owner = owner;
  }
}
