part of 'game_state.dart';

class LootCard {
  static const int _kHighCharCount = 4;
  static const int _kLowCharCount = 2;

  final String gfx;
  final int id;
  final LootBaseValue baseValue;
  final LootType lootType;
  String owner = '';
  int _enhanced = 0;
  int get enhanced => _enhanced;

  LootCard({
    required this.id,
    required this.lootType,
    required this.baseValue,
    required enhanced,
    required this.gfx,
  }) {
    _enhanced = enhanced;
  }

  Map<String, dynamic> toJson() => {
    'gfx': gfx,
    'owner': owner,
    'id': id,
    'enhanced': enhanced,
    'baseValue': baseValue.index,
    'lootType': lootType.index,
  };

  @override
  String toString() => json.encode(toJson());

  int? getValue() {
    int value = 1;
    if (lootType == LootType.other) {
      if (enhanced > 0) {
        return enhanced;
      }
      return null;
    }
    if (enhanced > 0) {
      value += enhanced;
    }
    final characters = GameMethods.getCurrentCharacterAmount();
    if (characters >= _kHighCharCount) {
      return value;
    }
    if (baseValue == LootBaseValue.oneIf4twoIfNot) {
      value++;
    } else if (characters <= _kLowCharCount &&
        baseValue == LootBaseValue.oneIf3or4twoIfNot) {
      value++;
    }
    return value;
  }
}

enum LootType { materiel, other }

enum LootBaseValue { one, oneIf4twoIfNot, oneIf3or4twoIfNot }
