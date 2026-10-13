import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_scope.dart';
import '../models.dart';
import '../theme.dart';

/// Priority is always shown with an icon + a word + a colour (never colour alone).
class PriorityStyle {
  final Color color;
  final IconData icon;
  final String label;
  const PriorityStyle(this.color, this.icon, this.label);
}

PriorityStyle priorityStyle(String p) {
  switch (p) {
    case 'critical':
      return const PriorityStyle(Brand.critical, Icons.error, 'CRITICAL');
    case 'high':
      return const PriorityStyle(Brand.high, Icons.warning_amber_rounded, 'HIGH');
    case 'medium':
      return const PriorityStyle(Brand.medium, Icons.info_outline, 'MEDIUM');
    default:
      return const PriorityStyle(Brand.low, Icons.check_circle_outline, 'LOW');
  }
}

IconData alertIcon(AlertItem a) {
  switch (a.type) {
    case 'doorbell':
      return Icons.notifications_active;
    case 'motion':
      return a.subType == 'human' ? Icons.directions_walk : Icons.sensors;
    case 'device_offline':
      return Icons.videocam_off;
    case 'device_online':
      return Icons.videocam;
    default:
      return Icons.notifications;
  }
}

String fmtWhen(DateTime t) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  final time = DateFormat.jm().format(t);
  if (diff == 0) return 'Today, $time';
  if (diff == 1) return 'Yesterday, $time';
  return '${DateFormat.MMMd().format(t)}, $time';
}

String decisionLabel(String d) {
  switch (d) {
    case 'pending':
      return 'Waiting for your decision';
    case 'auto_approved':
      return 'Pre-approved visitor';
    case 'approved':
      return 'You let them in';
    case 'denied':
      return 'You did not open';
    case 'wait':
      return 'You asked them to wait';
    default:
      return d;
  }
}

IconData decisionIcon(String d) {
  switch (d) {
    case 'pending':
      return Icons.hourglass_top;
    case 'auto_approved':
      return Icons.verified_user;
    case 'approved':
      return Icons.check_circle;
    case 'denied':
      return Icons.block;
    default:
      return Icons.schedule;
  }
}

void showMessage(BuildContext context, String? error, {String? ok}) {
  final text = error ?? ok;
  if (text == null) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text, style: const TextStyle(fontSize: 16))));
}

/// A card that lifts on hover and scales slightly on press, so the web app
/// feels interactive. On touch devices it behaves like a normal card.
class InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Border? border;
  final double radius;

  const InteractiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.border,
    this.radius = 20,
  });

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> {
  bool _hover = false;
  bool _pressed = false;

  bool get _enabled => widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.98 : 1.0;
    return MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.color ?? Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(widget.radius),
              border: widget.border,
              boxShadow: [
                BoxShadow(
                  color: Brand.squidInk.withValues(alpha: _hover ? 0.16 : 0.06),
                  blurRadius: _hover ? 22 : 10,
                  offset: Offset(0, _hover ? 8 : 3),
                ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class PriorityBadge extends StatelessWidget {
  final String priority;
  const PriorityBadge(this.priority, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = priorityStyle(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: s.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: s.color.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(s.icon, color: Colors.white, size: 20),
        const SizedBox(width: 6),
        Text(s.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.4)),
      ]),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 20, 4, 8),
        child: Row(children: [
          Container(
            width: 5,
            height: 22,
            decoration: BoxDecoration(color: Brand.orange, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(text, style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
        ]),
      );
}

/// Three big decision buttons for a visitor who is at the door.
class DecisionButtons extends StatelessWidget {
  final Arrival arrival;
  final VoidCallback? onDone;
  const DecisionButtons(this.arrival, {super.key, this.onDone});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    Future<void> go(String d) async {
      final err = await s.decide(arrival.id, d);
      if (!context.mounted) return;
      showMessage(context, err);
      if (err == null) onDone?.call();
    }

    return Wrap(spacing: 8, runSpacing: 8, children: [
      FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: Brand.low, foregroundColor: Colors.white, minimumSize: const Size(0, 52)),
        onPressed: () => go('approved'),
        icon: const Icon(Icons.check),
        label: const Text('Let them in'),
      ),
      FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: Brand.critical, foregroundColor: Colors.white, minimumSize: const Size(0, 52)),
        onPressed: () => go('denied'),
        icon: const Icon(Icons.block),
        label: const Text("Don't open"),
      ),
      FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: Brand.medium, foregroundColor: Colors.white, minimumSize: const Size(0, 52)),
        onPressed: () => go('wait'),
        icon: const Icon(Icons.schedule),
        label: const Text('Ask to wait'),
      ),
    ]);
  }
}

class AlertCard extends StatelessWidget {
  final AlertItem alert;
  const AlertCard(this.alert, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final st = priorityStyle(alert.priority);
    final arrival = s.arrivalFor(alert);
    final needsDecision = arrival != null && (arrival.decision == 'pending' || arrival.decision == 'wait');
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label: '${st.label} priority. ${alert.summary}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: InteractiveCard(
          onTap: (alert.isNew && !needsDecision) ? () async => showMessage(context, await s.ack(alert.id)) : null,
          border: Border(left: BorderSide(color: st.color, width: alert.isNew ? 5 : 3)),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              PriorityBadge(alert.priority),
              const Spacer(),
              if (!alert.isNew)
                Row(children: [
                  const Icon(Icons.done_all, size: 18),
                  const SizedBox(width: 4),
                  Text('Seen', style: theme.textTheme.bodyMedium),
                ]),
            ]),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(alertIcon(alert), size: 30, color: st.color),
              const SizedBox(width: 12),
              Expanded(child: Text(alert.summary, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 8),
            Text('${alert.deviceName}  •  ${fmtWhen(alert.time)}', style: theme.textTheme.bodyMedium),
            if (alert.isNew) ...[
              const SizedBox(height: 8),
              Text(alert.action, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
            if (arrival != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(decisionIcon(arrival.decision), size: 20),
                const SizedBox(width: 6),
                Expanded(child: Text(decisionLabel(arrival.decision), style: theme.textTheme.bodyLarge)),
              ]),
            ],
            if (needsDecision) ...[
              const SizedBox(height: 10),
              DecisionButtons(arrival!),
            ],
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text('Why this priority?'),
                children: [
                  for (final r in alert.reasons)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('•  $r', style: theme.textTheme.bodyMedium),
                      ),
                    ),
                ],
              ),
            ),
            if (alert.isNew && !needsDecision)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  onPressed: () async => showMessage(context, await s.ack(alert.id)),
                  icon: const Icon(Icons.check),
                  label: const Text('Got it'),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

