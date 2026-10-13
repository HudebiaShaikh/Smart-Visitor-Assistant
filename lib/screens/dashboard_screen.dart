import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final theme = Theme.of(context);
    final d = s.digest;
    final allClear = d.attention.isEmpty;
    final pendingArrivals = s.visitors.where((v) => v.decision == 'pending').toList();

    return RefreshIndicator(
      onRefresh: s.refresh,
      color: Brand.orange,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Semantics(
            liveRegion: true,
            child: _HeroSummary(
              allClear: allClear,
              headline: d.headline,
              accent: allClear ? Brand.low : priorityStyle(d.attention.first.priority).color,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final p in ['critical', 'high', 'medium', 'low'])
              _CountChip(p, d.counts[p] ?? 0),
          ]),
          if (pendingArrivals.isNotEmpty) ...[
            const SectionTitle('Someone is waiting'),
            for (final v in pendingArrivals)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InteractiveCard(
                  border: Border(left: BorderSide(color: Brand.high, width: 5)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.notifications_active, size: 28, color: Brand.high),
                      const SizedBox(width: 10),
                      Expanded(child: Text('${v.visitorName} at ${v.deviceName}', style: theme.textTheme.titleMedium)),
                    ]),
                    const SizedBox(height: 4),
                    Text(fmtWhen(v.time)),
                    const SizedBox(height: 10),
                    DecisionButtons(v),
                  ]),
                ),
              ),
          ],
          SectionTitle(allClear ? 'Needs your attention' : 'Look at these first'),
          if (allClear)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Nothing right now. New alerts will appear here and pop up on screen.', style: TextStyle(fontSize: 18)),
            )
          else
            for (final a in d.attention) AlertCard(a),
          if (s.mode == 'simulator' && s.scenarios.isNotEmpty) ...[
            const SectionTitle('Demo: simulate a Ring event'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final sc in s.scenarios)
                ActionChip(
                  avatar: const Icon(Icons.play_arrow),
                  label: Text(sc.label),
                  onPressed: () async => showMessage(context, await s.simulate(sc.id)),
                ),
            ]),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String priority;
  final int count;
  const _CountChip(this.priority, this.count);

  @override
  Widget build(BuildContext context) {
    final st = priorityStyle(priority);
    return Semantics(
      label: '$count ${st.label.toLowerCase()} priority alerts',
      child: ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            color: st.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: st.color, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(st.icon, color: st.color, size: 20),
              const SizedBox(width: 8),
              Text('${st.label[0]}${st.label.substring(1).toLowerCase()}: $count', style: const TextStyle(fontWeight: FontWeight.w700, color: Brand.textPrimary)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Big gradient summary card at the top of the Home tab.
class _HeroSummary extends StatelessWidget {
  final bool allClear;
  final String headline;
  final Color accent;
  const _HeroSummary({required this.allClear, required this.headline, required this.accent});

  @override
  Widget build(BuildContext context) {
    final top = allClear ? Brand.low : accent;
    final bottom = Color.lerp(top, Colors.black, 0.35)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [top, bottom]),
        boxShadow: [BoxShadow(color: top.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
            child: Icon(allClear ? Icons.shield : Icons.priority_high, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Home summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 16),
        Text(headline, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, height: 1.2)),
      ]),
    );
  }
}
