class AbilityTokenCatalog {
  AbilityTokenCatalog._();

  static const Map<String, String> tokens = {
    'attack': 'Attack',
    'move': 'Move',
    'teleport': 'Teleport',
    'range': 'Range',
    'heal': 'Heal',
    'target': 'Target',
    'shield': 'Shield',
    'loot': 'Loot',
    'retaliate': 'Retaliate',
    'jump': 'Jump',
    'stun': 'STUN',
    'wound': 'WOUND',
    'disarm': 'DISARM',
    'immobilize': 'IMMOBILIZE',
    'poison': 'POISON',
    'invisible': 'INVISIBLE',
    'strengthen': 'STRENGTHEN',
    'muddle': 'MUDDLE',
    'regenerate': 'REGENERATE',
    'ward': 'WARD',
    'impair': 'IMPAIR',
    'bane': 'BANE',
    'brittle': 'BRITTLE',
    'chill': 'CHILL',
    'infect': 'INFECT',
    'rupture': 'RUPTURE',
    'push': 'PUSH',
    'pull': 'PULL',
    'pierce': 'PIERCE',
    'curse': 'CURSE',
    'enfeeble': 'ENFEEBLE',
    'empower': 'EMPOWER',
    'bless': 'BLESS',
    'safeguard': 'SAFEGUARD',
    'flip': 'ROLLING',
    'damage': 'damage',
    'and': 'and',
  };

  static bool isElement(String token) =>
      token.contains('air') ||
      token.contains('earth') ||
      token.contains('fire') ||
      token.contains('ice') ||
      token.contains('dark') ||
      token.contains('light') ||
      token == 'any';
}
