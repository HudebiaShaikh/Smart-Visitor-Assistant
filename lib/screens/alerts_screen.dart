import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

const _rank = {'critical': 4, 'high': 3, 'medium': 2, 'low': 1};

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool onlyNew = false;
  bool byPriority = true;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    List<AlertItem> list = List.of(s.alerts);
    if (onlyNew) list = list.where((a) => a.isNew).toList();
    list.sort((a, b) {
      if (byPriority) {
        final n = (a.isNew ? 0 : 1) - (b.isNew ? 0 : 1);
        if (n != 0) return n;
        final r = (_rank[b.priority] ?? 0) - (_rank[a.priority] ?? 0);
        if (r != 0) return r;
      }
      return b.time.compareTo(a.time);
    });

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          FilterChip(
            label: const Text('Unseen only'),
            selected: onlyNew,
            onSelected: (v) => setState(() => onlyNew = v),
          ),
          ChoiceChip(
            label: const Text('Most important first'),
            selected: byPriority,
            onSelected: (_) => setState(() => byPriority = true),
          ),
          ChoiceChip(
            label: const Text('Newest first'),
            selected: !byPriority,
            onSelected: (_) => setState(() => byPriority = false),
          ),
          if (s.unread > 0)
            TextButton.icon(
              onPressed: () async => showMessage(context, await s.ackAll()),
              icon: const Icon(Icons.done_all),
              label: const Text('Mark all as seen'),
            ),
        ]),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: s.refresh,
          color: Brand.orange,
          child: list.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 90),
                  Icon(Icons.notifications_off_outlined, size: 64, color: Brand.squidInkLight),
                  SizedBox(height: 12),
                  Center(child: Text('No alerts yet.', style: TextStyle(fontSize: 20))),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) => AlertCard(list[i]),
                ),
        ),
      ),
    ]);
  }
}
