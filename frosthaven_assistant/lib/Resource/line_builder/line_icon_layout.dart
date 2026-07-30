import 'package:flutter/material.dart';

import 'ability_token_catalog.dart';

class LineIconLayout {
  LineIconLayout._();

  static const double oldStyleElementScale = 1.2;
  static const double _aoeScaleRatio = 2;
  static const double _centerMarginRatio = 0.2;
  static const double _statMarginRatio = 0.1;
  static const double _conditionMarginRatio = 0.25;

  static const Set<String> _mainLineMarginTokens = {
    'attack',
    'heal',
    'loot',
    'shield',
    'move',
  };

  static const Set<String> _secondaryMarginTokens = {
    'pierce',
    'target',
    'curse',
    'enfeeble',
    'bless',
    'push',
    'pull',
    'infect',
    'chill',
    'disarm',
    'immobilize',
    'stun',
    'strengthen',
    'impair',
    'bane',
    'brittle',
    'invisible',
    'safeguard',
    'muddle',
  };

  static double topPadding(TextStyle style) {
    final height = style.fontSize ?? 0;
    final markazi = style.fontFamily == 'Markazi';

    if (!markazi && style.height == 0.85) return height * 0.25;
    if (markazi && style.height == 0.84) return height * 0.1;
    return 0;
  }

  static double iconHeight(
    String token,
    double height,
    bool frosthavenStyle,
  ) {
    if (AbilityTokenCatalog.isElement(token)) {
      return frosthavenStyle ? height : height * oldStyleElementScale;
    }
    if (token.contains('aoe')) return height * _aoeScaleRatio;
    return height;
  }

  static EdgeInsetsGeometry marginForToken(
    String token,
    double height,
    bool mainLine,
    CrossAxisAlignment alignment,
    bool frosthavenStyle,
  ) {
    var margin = alignment == CrossAxisAlignment.center
        ? _centerMarginRatio
        : _statMarginRatio;
    if (frosthavenStyle) margin = 0;

    if (token.contains('aoe') ||
        (mainLine && _mainLineMarginTokens.contains(token))) {
      return EdgeInsets.symmetric(horizontal: margin * height);
    }

    final secondaryToken =
        _secondaryMarginTokens.contains(token) ||
        token.contains('poison') ||
        token.contains('wound');
    if (secondaryToken) {
      if (mainLine) return EdgeInsets.zero;
      if (frosthavenStyle && token != 'target') {
        return EdgeInsets.symmetric(
          horizontal: _conditionMarginRatio * height,
        );
      }
    }

    if (frosthavenStyle) return EdgeInsets.zero;
    return EdgeInsets.symmetric(horizontal: _statMarginRatio * height);
  }
}
