part of 'game_state.dart';

class ModifierDeckCodec {
  ModifierDeckCodec._();

  static void restore(
    ModifierDeck deck,
    Map<String, dynamic> modifierDeckData,
  ) {
    for (final key in deck._removables.keys) {
      deck._removables[key]?.value = 0;
    }
    deck._needsShuffle = false;

    for (final item in modifierDeckData['drawPile'] as List) {
      final String gfx = item['gfx'];
      if (gfx == 'curse' ||
          gfx.contains('empower') ||
          gfx.contains('enfeeble') ||
          gfx == 'bless') {
        deck.addRemovableValue(_StateModifier(), gfx, 1);
      }
    }
    for (final item in modifierDeckData['discardPile'] as List) {
      final String gfx = item['gfx'];
      if (deck._isMultiplyType(gfx)) {
        deck._needsShuffle = true;
      }
    }

    deck._drawPile.clear();
    deck._discardPile.clear();
    deck._removedPile.clear();
    deck._drawPile.setList(_cardsFromJson(deck, modifierDeckData, 'drawPile'));
    deck._discardPile.setList(
      _cardsFromJson(deck, modifierDeckData, 'discardPile'),
    );
    if (modifierDeckData.containsKey('removedPile')) {
      deck._removedPile.setList(
        _cardsFromJson(deck, modifierDeckData, 'removedPile'),
      );
    }

    deck._imbuement.value = modifierDeckData.containsKey('imbuement')
        ? modifierDeckData['imbuement'] as int
        : 0;
    deck._badOmen.value = modifierDeckData.containsKey('badOmen')
        ? modifierDeckData['badOmen'] as int
        : 0;
    deck._corrosiveSpew.value = modifierDeckData.containsKey('corrosiveSpew')
        ? modifierDeckData['corrosiveSpew'] as bool
        : false;
    deck._revealedCount.value = min(
      modifierDeckData.containsKey('revealed')
          ? modifierDeckData['revealed'] as int
          : 0,
      deck.drawPileSize,
    );
    deck._cassandraSpecial.value = modifierDeckData.containsKey('cassandra')
        ? modifierDeckData['cassandra'] as bool
        : false;
    deck._addedMinusOnes.value =
        modifierDeckData.containsKey('addedMinusOnes')
        ? modifierDeckData['addedMinusOnes'] as int
        : 0;
  }

  static Map<String, dynamic> serialize(ModifierDeck deck) => {
    'addedMinusOnes': deck._addedMinusOnes.value,
    'imbuement': deck._imbuement.value,
    'badOmen': deck._badOmen.value,
    'corrosiveSpew': deck._corrosiveSpew.value,
    'revealed': deck._revealedCount.value,
    'cassandra': deck._cassandraSpecial.value,
    'drawPile': deck._drawPile.getList().map((card) => card.toJson()).toList(),
    'removedPile': deck._removedPile
        .getList()
        .map((card) => card.toJson())
        .toList(),
    'discardPile': deck._discardPile
        .getList()
        .map((card) => card.toJson())
        .toList(),
  };

  static List<ModifierCard> _cardsFromJson(
    ModifierDeck deck,
    Map<String, dynamic> modifierDeckData,
    String deckId,
  ) {
    final cards = <ModifierCard>[];
    for (final item in modifierDeckData[deckId] as List) {
      String gfx = item['gfx'];
      gfx = gfx.replaceAll('-allies', '');
      if (gfx == 'curse') {
        cards.add(ModifierCard(CardType.remove, gfx));
      } else if (gfx.contains('enfeeble')) {
        if (gfx == 'enfeeble') {
          gfx = 'in-enfeeble';
        }
        cards.add(ModifierCard(CardType.remove, gfx));
      } else if (gfx.contains('empower') || gfx == 'bless') {
        cards.add(ModifierCard(CardType.remove, gfx));
      } else if (deck._isMultiplyType(gfx)) {
        cards.add(ModifierCard(CardType.multiply, gfx));
      } else {
        cards.add(ModifierCard(CardType.add, gfx));
      }
    }
    return cards;
  }
}
