import 'package:flutter/material.dart';

/// A printed ability card with modifier lines, distinct from the deck icon.
class OriginalAbilityCardIcon extends StatelessWidget {
  const OriginalAbilityCardIcon({super.key, this.size, this.color});

  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    return SizedBox.square(
      dimension: size ?? theme.size ?? 24,
      child: CustomPaint(
        painter: _OriginalAbilityCardPainter(
          color ?? theme.color ?? Colors.white,
        ),
      ),
    );
  }
}

class _OriginalAbilityCardPainter extends CustomPainter {
  const _OriginalAbilityCardPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4, 2, 16, 20),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawLine(const Offset(7.5, 6), const Offset(16.5, 6), paint);
    // The printed + / - distinguishes original modifiers from computed sums.
    canvas.drawLine(const Offset(7.5, 11), const Offset(11.5, 11), paint);
    canvas.drawLine(const Offset(9.5, 9), const Offset(9.5, 13), paint);
    canvas.drawLine(const Offset(14, 11), const Offset(16.5, 11), paint);
    canvas.drawLine(const Offset(7.5, 17), const Offset(11.5, 17), paint);
    canvas.drawLine(const Offset(14, 17), const Offset(16.5, 17), paint);
  }

  @override
  bool shouldRepaint(_OriginalAbilityCardPainter oldDelegate) =>
      oldDelegate.color != color;
}
