import 'package:flutter/material.dart';
import 'package:frosthaven_assistant/Resource/ui_tokens.dart';
import 'package:frosthaven_assistant/l10n/app_localizations.dart';

class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.child,
    this.maxWidth = UiModal.standardWidth,
    this.cardMargin,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? cardMargin;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Card(
        margin: cardMargin,
        child: Stack(children: [
          child,
          Positioned(
            width: UiTargetSize.closeButtonWidth,
            height: UiTargetSize.compact,
            right: 0,
            bottom: 0,
            child: TextButton(
              child: Text(
                AppLocalizations.of(context)!.close,
                style: UiTypography.buttonLabel,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ]),
      ),
    );
  }
}
