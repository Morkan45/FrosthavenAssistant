import 'package:flutter/material.dart';
import 'package:frosthaven_assistant/Resource/ui_tokens.dart';
import 'package:frosthaven_assistant/l10n/app_localizations.dart';

class ScrollableMenuCard extends StatefulWidget {
  const ScrollableMenuCard({
    super.key,
    required this.child,
    this.maxWidth,
    this.onClose,
  });

  final Widget child;
  final double? maxWidth;
  final VoidCallback? onClose;

  @override
  State<ScrollableMenuCard> createState() => _ScrollableMenuCardState();
}

class _ScrollableMenuCardState extends State<ScrollableMenuCard> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.maxWidth != null
        ? Container(
            constraints: BoxConstraints(maxWidth: widget.maxWidth!),
            child: widget.child,
          )
        : widget.child;
    return Card(
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Stack(children: [
            Column(
              children: [
                const SizedBox(height: UiSpacing.menuTop),
                content,
                const SizedBox(height: UiModal.closeButtonSpacing),
              ],
            ),
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
                  widget.onClose?.call();
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
