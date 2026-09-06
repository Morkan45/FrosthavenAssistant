import 'package:flutter/material.dart';
import 'package:frosthaven_assistant/Layout/ModifierCardWidget/modifier_card_front.dart';

import '../../Layout/widgets/modal_background.dart';
import '../../Resource/app_constants.dart';
import '../../Resource/commands/remove_amd_card_command.dart';
import '../../Resource/commands/return_modifier_card_command.dart';
import '../../Resource/game_methods.dart';
import '../../Resource/state/game_state.dart';
import '../../l10n/app_localizations.dart';
import '../../services/service_locator.dart';

class RemoveAMDCardMenu extends StatelessWidget {
  const RemoveAMDCardMenu({
    super.key,
    required this.index,
    required this.name,
    this.gameState,
  });

  final int index;
  final String name;

  final GameState? gameState;

  GameState get _gameState => gameState ?? getIt<GameState>();

  @override
  Widget build(BuildContext context) {
    final deck = GameMethods.getModifierDeck(name, _gameState);
    if (index >= deck.discardPileSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.pop(context);
      });
      return const SizedBox.shrink();
    }
    final card = deck.discardPileContents[index];
    final screenSize = MediaQuery.of(context).size;
    double scale = kCardZoomDefaultScale;
    final cardWidth = kCardZoomWidthFactor * kModifierCardBaseWidth;
    if (screenSize.width < cardWidth) {
      scale = kCardZoomDefaultScale * (screenSize.width / cardWidth);
    }
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ModifierCardFront(card: card, name: name, scale: scale),
          const SizedBox(height: kMenuTopPadding),
          ModalBackground(
            width: kMenuNarrowWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: kMenuTopPadding),
                TextButton(
                  onPressed: () {
                    _gameState.action(
                      RemoveAMDCardCommand(
                        index: index,
                        name: name,
                        gameState: _gameState,
                      ),
                    );

                    Navigator.pop(context);
                  },
                  child: Text(
                    AppLocalizations.of(context)!.removeCardQuestion,
                    textAlign: TextAlign.center,
                    style: kButtonLabelStyle,
                  ),
                ),
                const SizedBox(height: kMenuTopPadding),
                TextButton(
                  onPressed: () {
                    _gameState.action(ReturnModifierCardCommand(name));
                    final deck = GameMethods.getModifierDeck(name, _gameState);
                    //if last card, remove modal
                    if (deck.discardPileIsEmpty) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    AppLocalizations.of(context)!.returnTopCard,
                    textAlign: TextAlign.center,
                    style: kButtonLabelStyle,
                  ),
                ),
                const SizedBox(height: kMenuTopPadding),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
