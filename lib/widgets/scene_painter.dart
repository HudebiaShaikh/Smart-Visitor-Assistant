import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Paints a stylised front-door scene: sky gradient, house frame, porch light,
/// path, drifting dust motes and a scanning sweep. The [t] value drives a
/// subtle camera drift so the "video" never looks frozen. When [visitor] is
/// true a silhouette stands on the path.
class ScenePainter extends CustomPainter {
  final double t;
  final bool visitor;
  ScenePainter({required this.t, required this.visitor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final drift = math.sin(t * 2 * math.pi) * 3;

    // Sky / night gradient.
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: visitor
            ? [const Color(0xFF2A2438), const Color(0xFF4A3A2A)]
            : [const Color(0xFF1B2430), const Color(0xFF2C3A47)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sky);

    // Distant wall.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.10 + drift, h * 0.18, w * 0.80, h * 0.62),
      Paint()..color = const Color(0xFF3B4A57),
    );

    // Door frame.
    final door = Rect.fromLTWH(w * 0.38 + drift, h * 0.26, w * 0.24, h * 0.60);
    canvas.drawRect(door, Paint()..color = const Color(0xFF22303C));
    canvas.drawRect(door.deflate(6), Paint()..color = const Color(0xFF16222C));
    canvas.drawCircle(Offset(door.left + 10, door.center.dy), 3, Paint()..color = Brand.orange);

    // Porch light glow above the door.
    final glow = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFFFFD79A).withValues(alpha: visitor ? 0.95 : 0.55),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: Offset(door.center.dx, door.top + 12), radius: w * 0.28));
    canvas.drawCircle(Offset(door.center.dx, door.top + 12), w * 0.28, glow);

    // Ground / path.
    canvas.drawRect(Rect.fromLTWH(0, h * 0.80, w, h * 0.20), Paint()..color = const Color(0xFF141C24));
    canvas.drawRect(
      Rect.fromLTWH(w * 0.44 + drift, h * 0.80, w * 0.12, h * 0.20),
      Paint()..color = const Color(0xFF39485A),
    );

    // Visitor silhouette.
    if (visitor) {
      final cx = w * 0.50 + drift;
      final base = h * 0.80;
      final body = Paint()..color = const Color(0xFF0C0F13);
      canvas.drawCircle(Offset(cx, base - h * 0.30), w * 0.035, body);
      final torso = Path()
        ..moveTo(cx - w * 0.05, base)
        ..lineTo(cx - w * 0.045, base - h * 0.24)
        ..quadraticBezierTo(cx, base - h * 0.30, cx + w * 0.045, base - h * 0.24)
        ..lineTo(cx + w * 0.05, base)
        ..close();
      canvas.drawPath(torso, body);
    }

    // Drifting dust motes for a "video" feel.
    final rnd = math.Random(7);
    for (var i = 0; i < 18; i++) {
      final bx = rnd.nextDouble() * w;
      final by = rnd.nextDouble() * h;
      final yy = (by + t * 30 * (0.5 + rnd.nextDouble())) % h;
      final alpha = 0.05 + 0.10 * ((math.sin(t * 2 * math.pi + i) + 1) / 2);
      canvas.drawCircle(Offset(bx, yy), rnd.nextDouble() * 1.6 + 0.6, Paint()..color = Colors.white.withValues(alpha: alpha));
    }

    // Scanning sweep line.
    final sweepX = ((t % 1.0) * 2 - 0.5).clamp(0.0, 1.0) * w;
    final sweep = Paint()
      ..shader = LinearGradient(colors: [
        Colors.transparent,
        Colors.white.withValues(alpha: 0.05),
        Colors.transparent,
      ]).createShader(Rect.fromLTWH(sweepX - 40, 0, 80, h));
    canvas.drawRect(Rect.fromLTWH(sweepX - 40, 0, 80, h), sweep);

    // Vignette.
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
        stops: const [0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), vignette);
  }

  @override
  bool shouldRepaint(covariant ScenePainter old) => old.t != t || old.visitor != visitor;
}
