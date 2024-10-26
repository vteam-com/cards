import 'package:flutter/material.dart';

class FeltTablePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Paint for the green felt
    final Paint greenPaint = Paint()
      ..color = const Color(0xFF228B22) // Adjust this for felt color
      ..style = PaintingStyle.fill;

    // Rect covering the entire background
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw the green background
    canvas.drawRect(rect, greenPaint);

    // Paint for the highlight/shiny area
    final Paint highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.8],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width / 2));

    // Draw the radial gradient for the shine
    canvas.drawCircle(Offset(size.width / 2, size.height / 3), size.width / 3,
        highlightPaint);

    // Paint for vignette effect
    final Paint vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.5),
        ],
        stops: const [0.7, 1.0],
      ).createShader(rect);

    // Draw the vignette
    canvas.drawRect(rect, vignettePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // No need to repaint unless static assets change
  }
}
