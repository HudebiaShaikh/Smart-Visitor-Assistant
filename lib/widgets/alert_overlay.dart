import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../app_state.dart';
import '../models.dart';
import 'common.dart';

/// Full-screen alert for critical/high events. Big text, big buttons, and a slow
/// (under 1 flash per second) colour pulse for people who cannot hear the doorbell.
class AlertOverlay extends StatefulWidget {
  final AlertItem alert;
  const AlertOverlay({super.key, required this.alert});

  @override
  State<AlertOverlay> createState() => _AlertOverlayState();
}

class _AlertOverlayState extends State<AlertOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final a = widget.alert;
    final st = priorityStyle(a.priority);
    final arrival = s.arrivalFor(a);
    final needsDecision = arrival != null && arrival.decision == 'pending';

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final t = s.flashAlerts ? _pulse.value : 0.0;
          final bg = Color.lerp(st.color, Colors.black, 0.15 + 0.35 * t)!;
          return Container(
            color: bg,
            child: SafeArea(
              child: Semantics(
                liveRegion: true,
                label: '${st.label} alert. ${a.summary} ${a.action}',
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Icon(alertIcon(a), size: 96, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      '${st.label} ALERT',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 16),
                    Text(a.summary, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Text(a.action, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 28),
                    if (needsDecision) ...[
                      _white('Let them in', Icons.check, () => _decide(s, arrival!, 'approved')),
                      const SizedBox(height: 12),
                      _white("Don't open", Icons.block, () => _decide(s, arrival!, 'denied')),
                      const SizedBox(height: 12),
                      _white('Ask them to wait', Icons.schedule, () => _decide(s, arrival!, 'wait')),
                    ] else
                      _white("I've seen it", Icons.check, () async {
                        await s.ack(a.id);
                        s.dismissOverlay();
                      }),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: s.dismissOverlay,
                      style: TextButton.styleFrom(foregroundColor: Colors.white, minimumSize: const Size(0, 48)),
                      child: const Text('Close for now', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _decide(AppState s, Arrival arrival, String d) async {
    await s.decide(arrival.id, d);
    s.dismissOverlay();
  }

  Widget _white(String label, IconData icon, VoidCallback onTap) => FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          minimumSize: const Size.fromHeight(64),
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 28),
        label: Text(label),
      );
}
