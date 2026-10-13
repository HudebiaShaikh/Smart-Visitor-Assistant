import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

const _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

String _hhmm(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

TimeOfDay _parse(String s) {
  final p = s.split(':');
  return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
}

String describeWindow(PreApproved p) {
  final days = p.days.isEmpty ? 'Every day' : p.days.map((d) => _dayNames[d]).join(', ');
  final extra = [
    if (p.oneTime) 'one visit only',
    if (p.validUntil != null) 'until ${p.validUntil}',
  ];
  return '$days, ${p.from} to ${p.to}${extra.isEmpty ? '' : ' (${extra.join(', ')})'}';
}

class VisitorsScreen extends StatelessWidget {
  const VisitorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(children: const [
        TabBar(tabs: [
          Tab(icon: Icon(Icons.history), text: 'Visitor history'),
          Tab(icon: Icon(Icons.verified_user), text: 'Expected visitors'),
        ]),
        Expanded(child: TabBarView(children: [_HistoryTab(), _PreApprovedTab()])),
      ]),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: s.refresh,
      color: Brand.orange,
      child: s.visitors.isEmpty
          ? ListView(children: const [
              SizedBox(height: 90),
              Icon(Icons.history, size: 64, color: Brand.squidInkLight),
              SizedBox(height: 12),
              Center(child: Text('No visitors yet.', style: TextStyle(fontSize: 20))),
            ])
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: s.visitors.length,
              itemBuilder: (_, i) {
                final v = s.visitors[i];
                final open = v.decision == 'pending' || v.decision == 'wait';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InteractiveCard(
                    border: Border(left: BorderSide(color: open ? Brand.high : Brand.squidInkLight, width: 5)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(v.expected ? Icons.verified_user : Icons.person_outline, size: 30, color: Brand.linkBlue),
                        const SizedBox(width: 12),
                        Expanded(child: Text(v.visitorName, style: theme.textTheme.titleMedium)),
                      ]),
                      const SizedBox(height: 6),
                      Text('Entry time: ${fmtWhen(v.time)}', style: theme.textTheme.bodyLarge),
                      Text(v.deviceName, style: theme.textTheme.bodyMedium),
                      if (v.note.isNotEmpty) Text(v.note, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(decisionIcon(v.decision), size: 20),
                        const SizedBox(width: 6),
                        Expanded(child: Text(decisionLabel(v.decision), style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600))),
                      ]),
                      if (open) ...[
                        const SizedBox(height: 10),
                        DecisionButtons(v),
                      ],
                    ]),
                  ),
                );
              },
            ),
    );
  }
}

class _PreApprovedTab extends StatelessWidget {
  const _PreApprovedTab();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _PreApprovedForm(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add visitor'),
      ),
      body: s.preapproved.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
                  Icon(Icons.verified_user, size: 64, color: Brand.squidInkLight),
                  SizedBox(height: 12),
                  Text(
                    'No expected visitors. Add someone (a plumber, a family member) so their arrival is marked as expected and does not raise an alarm.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                ]),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: s.preapproved.length,
              itemBuilder: (_, i) {
                final p = s.preapproved[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      if (p.note.isNotEmpty) Text(p.note, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 4),
                      Text(describeWindow(p), style: theme.textTheme.bodyMedium),
                      if (p.used) Text('Already used', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(p.active ? 'Active' : 'Paused'),
                            value: p.active,
                            onChanged: (v) async => showMessage(context, await s.updatePreapproved(p.id, {'active': v})),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete ${p.name}',
                          iconSize: 30,
                          onPressed: () async => showMessage(context, await s.deletePreapproved(p.id)),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ]),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}

class _PreApprovedForm extends StatefulWidget {
  const _PreApprovedForm();

  @override
  State<_PreApprovedForm> createState() => _PreApprovedFormState();
}

class _PreApprovedFormState extends State<_PreApprovedForm> {
  final name = TextEditingController();
  final note = TextEditingController();
  final days = <int>{};
  String from = '09:00';
  String to = '18:00';
  bool oneTime = false;
  DateTime? validUntil;
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> pick(bool isFrom) async {
    final t = await showTimePicker(context: context, initialTime: _parse(isFrom ? from : to));
    if (t != null) setState(() => isFrom ? from = _hhmm(t) : to = _hhmm(t));
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: validUntil ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => validUntil = d);
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty) {
      showMessage(context, 'Please enter a name.');
      return;
    }
    setState(() => saving = true);
    final s = AppScope.of(context);
    final v = validUntil;
    final err = await s.addPreapproved({
      'name': name.text.trim(),
      'note': note.text.trim(),
      'days': days.toList()..sort(),
      'from': from,
      'to': to,
      'oneTime': oneTime,
      'validUntil': v == null ? null : '${v.year.toString().padLeft(4, '0')}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}',
    });
    if (!mounted) return;
    setState(() => saving = false);
    if (err != null) {
      showMessage(context, err);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Add expected visitor', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Name (for example: Plumber)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: note, decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          const Text('Days (leave empty for every day)'),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (var i = 0; i < 7; i++)
              FilterChip(
                label: Text(_dayNames[i]),
                selected: days.contains(i),
                onSelected: (v) => setState(() => v ? days.add(i) : days.remove(i)),
              ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => pick(true), icon: const Icon(Icons.schedule), label: Text('From $from'))),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton.icon(onPressed: () => pick(false), icon: const Icon(Icons.schedule), label: Text('To $to'))),
          ]),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('One visit only'), value: oneTime, onChanged: (v) => setState(() => oneTime = v)),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: pickDate,
                icon: const Icon(Icons.event),
                label: Text(validUntil == null ? 'Valid until: no end date' : 'Valid until ${validUntil!.day}/${validUntil!.month}/${validUntil!.year}'),
              ),
            ),
            if (validUntil != null) IconButton(tooltip: 'Clear date', onPressed: () => setState(() => validUntil = null), icon: const Icon(Icons.clear)),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              onPressed: saving ? null : save,
              child: Text(saving ? 'Saving...' : 'Save visitor', style: const TextStyle(fontSize: 18)),
            ),
          ),
        ]),
      ),
    );
  }
}
