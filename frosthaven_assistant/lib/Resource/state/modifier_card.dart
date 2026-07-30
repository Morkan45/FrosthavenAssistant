part of 'game_state.dart';

enum CardType { add, multiply, remove }

class ModifierCard {
  final CardType type;
  final String gfx;

  ModifierCard(this.type, this.gfx);

  Map<String, dynamic> toJson() => {'gfx': gfx};

  @override
  String toString() => '{"gfx": "$gfx" }';
}
