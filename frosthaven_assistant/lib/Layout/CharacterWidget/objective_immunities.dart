import 'package:flutter/material.dart';

import '../../Resource/ui_utils.dart';
import '../../l10n/app_localizations.dart';

/// Uses the same immunity symbol as monster stat cards for blanket immunity.
class ObjectiveImmunities extends StatelessWidget {
  const ObjectiveImmunities({super.key, required this.scale});

  static const double _width = 46;
  static const double _height = 40;
  static const double _iconHeight = 10;
  static const double _fontSize = 9;
  static const double _spacing = 2;

  final double scale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: l10n.objectiveConditionImmunity,
      child: Semantics(
        label: l10n.objectiveConditionImmunity,
        excludeSemantics: true,
        child: SizedBox(
          width: _width * scale,
          height: _height * scale,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image(
                height: _iconHeight * scale,
                filterQuality: powerAwareFilterQuality(),
                image: const AssetImage('assets/images/psd/immune.png'),
              ),
              SizedBox(height: _spacing * scale),
              Flexible(
                child: Text(
                  l10n.allConditions,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _fontSize * scale,
                    height: 1,
                    shadows: [textShadow(scale)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
