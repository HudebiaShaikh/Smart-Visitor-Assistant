import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'scene_painter.dart';

/// A simulated "live" doorbell camera. Because a browser tab has no Ring
/// hardware, this paints an animated doorway scene (see [_ScenePainter]) with a
/// real-world HUD on top: LIVE badge, clock and camera label. It reacts to an
/// external [visitorPresent] flag so a pending visitor turns the feed amber and
/// shows a detection box.
class LiveCamera extends StatefulWidget {
  final bool visitorPresent;
  const LiveCamera({super.key, this.visitorPresent = false});

  @override
  State<LiveCamera> createState() => _LiveCameraState();
}

class _LiveCameraState extends State<LiveCamera> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  String get _clockText {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    final s = _now.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final visitor = widget.visitorPresent;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(fit: StackFit.expand, children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(painter: ScenePainter(t: _ctrl.value, visitor: visitor)),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            color: visitor ? Brand.orange.withValues(alpha: 0.12) : Colors.transparent,
          ),
          if (visitor)
            Positioned(
              left: 26,
              right: 26,
              bottom: 40,
              child: Container(
                height: 118,
                decoration: BoxDecoration(
                  border: Border.all(color: Brand.orange, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  color: Brand.orange.withValues(alpha: 0.06),
                ),
                child: const Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    child: Text('PERSON',
                        style: TextStyle(color: Brand.orange, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1)),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(children: [
              _HudPill(icon: Icons.fiber_manual_record, color: const Color(0xFFFF4D4D), label: 'LIVE'),
              const Spacer(),
              _HudPill(icon: Icons.access_time, color: Colors.white, label: _clockText),
            ]),
          ),
          Positioned(
            bottom: 10,
            left: 12,
            child: Row(children: [
              const Icon(Icons.videocam, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(visitor ? 'Front Door • motion' : 'Front Door',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _HudPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _HudPill({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11.5)),
      ]),
    );
  }
}
