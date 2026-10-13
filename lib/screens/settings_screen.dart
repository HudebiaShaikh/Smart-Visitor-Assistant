import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController url;
  late final TextEditingController key;

  @override
  void initState() {
    super.initState();
    url = TextEditingController();
    key = TextEditingController();
  }

  bool _filled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_filled) {
      final s = AppScope.of(context);
      url.text = s.baseUrl;
      key.text = s.apiKey;
      _filled = true;
    }
  }

  @override
  void dispose() {
    url.dispose();
    key.dispose();
    super.dispose();
  }

  Future<void> pickQuiet(bool start) async {
    final s = AppScope.of(context);
    final cur = (start ? s.quietStart : s.quietEnd).split(':');
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: int.parse(cur[0]), minute: int.parse(cur[1])));
    if (t == null || !mounted) return;
    final v = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final err = await s.saveQuiet(start ? v : s.quietStart, start ? s.quietEnd : v);
    if (mounted) showMessage(context, err);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle('Easy to read'),
        InteractiveCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Text size', style: theme.textTheme.titleMedium),
            Slider(
              value: s.textScale,
              min: 1.0,
              max: 2.0,
              divisions: 10,
              label: '${(s.textScale * 100).round()}%',
              semanticFormatterCallback: (v) => 'Text size ${(v * 100).round()} percent',
              onChanged: s.setTextScale,
            ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('High contrast (black and yellow)'),
                value: s.highContrast,
                onChanged: s.setHighContrast,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Flashing colour on urgent alerts'),
                subtitle: const Text('A slow colour pulse, less than once per second. Helpful if you cannot hear the doorbell.'),
                value: s.flashAlerts,
                onChanged: s.setFlash,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vibrate on alerts'),
                value: s.vibrate,
                onChanged: s.setVibrate,
              ),
            ]),
        ),
        const SectionTitle('Quiet hours'),
        InteractiveCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Visitors and people seen during these hours are treated as more urgent.'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => pickQuiet(true), icon: const Icon(Icons.bedtime), label: Text('From ${s.quietStart}'))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(onPressed: () => pickQuiet(false), icon: const Icon(Icons.wb_sunny), label: Text('To ${s.quietEnd}'))),
            ]),
          ]),
        ),
        const SectionTitle('Server connection'),
        InteractiveCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(controller: url, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'Server address', hintText: 'http://localhost:3000', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: key, obscureText: true, decoration: const InputDecoration(labelText: 'API key (only if you set APP_API_KEY)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: () async {
                await s.setConnection(url.text, key.text);
                if (!context.mounted) return;
                showMessage(context, s.connected ? 'Connected (${s.mode} mode)' : (s.error ?? 'Could not connect'));
              },
              icon: const Icon(Icons.wifi),
              label: const Text('Save and test'),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Icon(s.connected ? Icons.check_circle : Icons.error, color: s.connected ? Brand.low : Brand.critical),
              const SizedBox(width: 8),
              Expanded(child: Text(s.connected ? 'Connected${s.mode.isEmpty ? '' : ' - ${s.mode} mode'}' : 'Not connected')),
            ]),
          ]),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
