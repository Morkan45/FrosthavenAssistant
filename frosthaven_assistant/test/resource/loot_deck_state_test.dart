import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';

void main() {
  group('LootDeck serialization', () {
    test('restores current save values and serializes them unchanged', () {
      final deck = LootDeck.fromJson({
        '1418': true,
        '1419': false,
        'addedCards': [1, 0, 0, 0, 0, 0, 0, 0, 0],
        'enhancements': {'42': 2},
        'drawPile': [
          {
            'gfx': 'lumber',
            'owner': 'Banner Spear',
            'id': 42,
            'enhanced': 2,
            'baseValue': LootBaseValue.oneIf4twoIfNot.index,
            'lootType': LootType.materiel.index,
          },
        ],
        'discardPile': <Map<String, dynamic>>[],
      });

      final card = deck.drawPileTop;
      expect(card.id, 42);
      expect(card.owner, 'Banner Spear');
      expect(card.enhanced, 2);
      expect(card.baseValue, LootBaseValue.oneIf4twoIfNot);
      expect(card.lootType, LootType.materiel);
      expect(deck.hasCard1418, isTrue);
      expect(deck.hasCard1419, isFalse);
      expect(deck.addedCards.first, 1);
      expect(deck.toJson()['enhancements'], {'42': 2});
    });

    test('migrates legacy enhancement and missing card fields', () {
      final deck = LootDeck.fromJson({
        '1418': false,
        '1419': false,
        'drawPile': [
          {
            'gfx': 'coin 1',
            'id': 7,
            'enhanced': true,
            'baseValue': 99,
            'lootType': 99,
          },
          {
            'gfx': 'coin 2',
            'enhanced': false,
          },
        ],
        'discardPile': [
          {
            'gfx': 'coin 3',
            'enhanced': 3.0,
          },
        ],
      });

      final drawCards = deck.drawPileContents;
      expect(drawCards.first.enhanced, 1);
      expect(drawCards.first.baseValue, LootBaseValue.values.first);
      expect(drawCards.first.lootType, LootType.values.first);
      expect(drawCards.last.id, 7);
      expect(drawCards.last.owner, isEmpty);
      expect(deck.discardPileTop.id, 7);
      expect(deck.discardPileTop.enhanced, 3);
      expect(deck.addedCards, everyElement(0));
      expect(deck.toJson()['enhancements'], isEmpty);
    });
  });
}
