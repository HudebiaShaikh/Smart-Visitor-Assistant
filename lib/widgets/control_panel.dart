import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models.dart';
import '../theme.dart';
import 'brand_logo.dart';
import 'common.dart';
import 'live_camera.dart';

/// The right-hand "Control Center". Holds the live camera, one-tap door
/// actions, smart-home device toggles and a compact activity feed. Purely a UI
/// layer over [AppState] (plus a little local state for the toggles that have
/// no backend endpoint yet).
class ControlPanel extends StatefulWidget {
  const ControlPanel({super.key});

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  bool micOn = true;
  bool speakerOn = false;
  bool recording = false;
  bool porchLight = true;
  bool nightVision = false;
  bool sirenOn = false;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final pending = s.visitors.where((v) => v.decision == 'pending').toList();
    final visitorPresent = pending.isNotEmpty;

    return Container(
      width: 360,
      decoration: const BoxDecoration(
        color: Brand.surface,
        border: Border(left: BorderSide(color: Brand.divider)),
      ),
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          const BrandMark(size: 24),
          const SizedBox(width: 8),
          Text('Control Center', style: Theme.of(context).textTheme.titleMedium),
        ]),
        const SizedBox(height: 14),

        // Live camera.
        LiveCamera(visitorPresent: visitorPresent),
        const SizedBox(height: 12),

        // One-tap actions.
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _CamAction(icon: micOn ? Icons.mic : Icons.mic_off, label: micOn ? 'Mute' : 'Unmute', active: micOn, onTap: () => setState(() => micOn = !micOn)),
          _CamAction(icon: Icons.volume_up, label: 'Talk', active: speakerOn, onTap: () => setState(() => speakerOn = !speakerOn)),
          _CamAction(
            icon: recording ? Icons.stop_circle : Icons.videocam,
            label: recording ? 'Stop' : 'Record',
            active: recording,
            onTap: () => setState(() => recording = !recording),
          ),
          _CamAction(
            icon: nightVision ? Icons.wb_sunny : Icons.nightlight_round,
            label: nightVision ? 'Day' : 'Night',
            active: nightVision,
            onTap: () => setState(() => nightVision = !nightVision),
          ),
        ]),
        const SizedBox(height: 20),

        // Door & safety.
        _PanelCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Door & safety', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  onPressed: () => showMessage(context, null, ok: 'Door unlocked for 30 seconds'),
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Unlock'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    side: BorderSide(color: sirenOn ? Brand.critical : Brand.squidInkLight),
                    foregroundColor: sirenOn ? Brand.critical : Brand.squidInk,
                  ),
                  onPressed: () => setState(() => sirenOn = !sirenOn),
                  icon: Icon(sirenOn ? Icons.notifications_active : Icons.notifications_off),
                  label: Text(sirenOn ? 'Siren ON' : 'Siren'),
                ),
              ),
            ]),
            if (sirenOn)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(children: [
                  Icon(Icons.warning_amber_rounded, color: Brand.critical, size: 18),
                  SizedBox(width: 6),
                  Expanded(child: Text('Siren is active. Tap again to stop.', style: TextStyle(color: Brand.critical, fontWeight: FontWeight.w600))),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 12),

        // Device toggles.
        _PanelCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Devices', style: Theme.of(context).textTheme.titleSmall),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(Icons.lightbulb, color: porchLight ? Brand.orange : Brand.textMuted),
              title: const Text('Porch light'),
              value: porchLight,
              onChanged: (v) => setState(() => porchLight = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.thermostat, color: Brand.linkBlue),
              title: const Text('Smart doorbell'),
              subtitle: Text(s.connected ? 'Online' : 'Offline'),
              value: s.connected,
              onChanged: null,
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // Activity feed.
        Text('Recent activity', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _ActivityFeed(alerts: s.alerts.take(6).toList()),
        const SizedBox(height: 12),
      ]),
    );
  }
}

class _CamAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _CamAction({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Semantics(
          button: true,
          selected: active,
          label: label,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active ? Brand.orangeSoft : Brand.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: active ? Brand.orange : Brand.divider),
              ),
              child: Column(children: [
                Icon(icon, size: 20, color: active ? Brand.orangeDark : Brand.squidInkLight),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? Brand.orangeDark : Brand.textMuted)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  final Widget child;
  const _PanelCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Brand.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Brand.divider),
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

class _ActivityFeed extends StatelessWidget {
  final List<AlertItem> alerts;
  const _ActivityFeed({required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Brand.bg, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const Icon(Icons.history, color: Brand.textMuted),
          const SizedBox(width: 10),
          Expanded(child: Text('No activity yet.', style: Theme.of(context).textTheme.bodyMedium)),
        ]),
      );
    }
    return Column(children: [
      for (final a in alerts)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: priorityStyle(a.priority).color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(alertIcon(a), size: 18, color: priorityStyle(a.priority).color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(fmtWhen(a.time), style: Theme.of(context).textTheme.bodyMedium),
              ]),
            ),
          ]),
        ),
    ]);
  }
}

