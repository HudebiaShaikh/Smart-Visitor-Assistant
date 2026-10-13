import 'package:flutter/material.dart';

import '../theme.dart';

/// Brand lockup: the Amazon "smile" mark plus the product wordmark.
/// Drawn with a [CustomPainter] so there is no image asset to ship and it
/// scales cleanly on any screen.
class BrandLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  const BrandLogo({super.key, this.size = 30, this.showWordmark = true});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Semantics(
        label: 'Amazon',
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _SmilePainter()),
        ),
      ),
      if (showWordmark) ...[
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart Visitor',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.52, height: 1.05, letterSpacing: -0.2)),
            Text('by Ring',
                style: TextStyle(color: Brand.orangeLight, fontWeight: FontWeight.w700, fontSize: size * 0.34, height: 1.1)),
          ],
        ),
      ],
    ]);
  }
}

/// Just the smile glyph on its own (used where the wordmark would be too much).
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Amazon',
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _SmilePainter()),
        ),
      );
}

class _SmilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Wordmark dot row (the little circles above the smile).
    final dot = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.18, h * 0.30), w * 0.055, dot);
    canvas.drawCircle(Offset(w * 0.34, h * 0.24), w * 0.055, dot);
    canvas.drawCircle(Offset(w * 0.52, h * 0.24), w * 0.055, dot);
    canvas.drawCircle(Offset(w * 0.70, h * 0.30), w * 0.055, dot);

    // The orange smile: a wide arc from the left under to the right, with an
    // upward flick at the right tip like the Amazon logo.
    final paint = Paint()
      ..color = Brand.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.10
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(w * 0.08, h * 0.42);
    path.quadraticBezierTo(w * 0.5, h * 0.95, w * 0.86, h * 0.55);
    canvas.drawPath(path, paint);

    // Small upward flick at the right tip.
    final flick = Path();
    flick.moveTo(w * 0.86, h * 0.55);
    flick.quadraticBezierTo(w * 0.95, h * 0.62, w * 0.99, h * 0.50);
    canvas.drawPath(flick, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
