import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'models.dart';

/// Default server address per platform (Android emulator reaches your PC via 10.0.2.2).
String defaultBaseUrl() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
  return 'http://localhost:3000';
}

class AppState extends ChangeNotifier {
  late ApiClient api;

  // Accessibility + connection settings (saved on the device)
  double textScale = 1.2;
  bool highContrast = false;
  bool flashAlerts = true;
  bool vibrate = true;
  String baseUrl = defaultBaseUrl();
  String apiKey = '';

  // Data
  List<AlertItem> alerts = [];
  List<Arrival> visitors = [];
  List<PreApproved> preapproved = [];
  Digest digest = Digest.empty();
  List<Scenario> scenarios = [];
  String mode = '';
  int unread = 0;
  int pending = 0;
  String quietStart = '22:00';
  String quietEnd = '06:00';

  bool connected = false;
  bool loading = true;
  String? error;

  /// Alert currently shown full-screen (critical/high doorbell or person alerts).
  AlertItem? overlay;

  bool _disposed = false;
  bool _streaming = false;

  AppState() {
    api = ApiClient(baseUrl: baseUrl);
  }

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    textScale = p.getDouble('textScale') ?? 1.2;
    highContrast = p.getBool('highContrast') ?? false;
    flashAlerts = p.getBool('flashAlerts') ?? true;
    vibrate = p.getBool('vibrate') ?? true;
    baseUrl = p.getString('baseUrl') ?? defaultBaseUrl();
    apiKey = p.getString('apiKey') ?? '';
    api = ApiClient(baseUrl: baseUrl, apiKey: apiKey);
    notifyListeners();
    await refresh();
    _startStream();
  }

  Future<void> savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('textScale', textScale);
    await p.setBool('highContrast', highContrast);
    await p.setBool('flashAlerts', flashAlerts);
    await p.setBool('vibrate', vibrate);
    await p.setString('baseUrl', baseUrl);
    await p.setString('apiKey', apiKey);
  }

  void setTextScale(double v) {
    textScale = v;
    savePrefs();
    notifyListeners();
  }

  void setHighContrast(bool v) {
    highContrast = v;
    savePrefs();
    notifyListeners();
  }

  void setFlash(bool v) {
    flashAlerts = v;
    savePrefs();
    notifyListeners();
  }

  void setVibrate(bool v) {
    vibrate = v;
    savePrefs();
    notifyListeners();
  }

  Future<void> setConnection(String url, String key) async {
    baseUrl = url.trim();
    apiKey = key.trim();
    api = ApiClient(baseUrl: baseUrl, apiKey: apiKey);
    await savePrefs();
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final results = await Future.wait([
        api.status(),
        api.alerts(),
        api.digest(),
        api.visitors(),
        api.preapproved(),
      ]);
      final st = results[0] as Map<String, dynamic>;
      mode = (st['mode'] ?? '') as String;
      unread = ((st['unread'] ?? 0) as num).toInt();
      pending = ((st['pendingVisitors'] ?? 0) as num).toInt();
      final settings = (st['settings'] ?? {}) as Map;
      quietStart = (settings['quietStart'] ?? quietStart) as String;
      quietEnd = (settings['quietEnd'] ?? quietEnd) as String;
      scenarios = ((st['scenarios'] ?? []) as List)
          .map((e) => Scenario((e as Map)['id'] as String, e['label'] as String))
          .toList();
      alerts = results[1] as List<AlertItem>;
      digest = results[2] as Digest;
      visitors = results[3] as List<Arrival>;
      preapproved = results[4] as List<PreApproved>;
      connected = true;
      error = null;
    } catch (e) {
      connected = false;
      error = e.toString();
    }
    loading = false;
    _notify();
  }

  void _startStream() {
    if (_streaming) return;
    _streaming = true;
    () async {
      while (!_disposed) {
        try {
          await for (final ev in api.stream()) {
            connected = true;
            if (ev.key == 'alert') {
              final a = AlertItem.fromJson(ev.value as Map<String, dynamic>);
              _onNewAlert(a);
            }
            await refresh();
          }
        } catch (_) {
          connected = false;
          _notify();
        }
        await Future.delayed(const Duration(seconds: 3)); // reconnect
      }
    }();
  }

  void _onNewAlert(AlertItem a) {
    final loud = a.priority == 'critical' || a.priority == 'high';
    if (loud) {
      overlay = a;
      if (vibrate) {
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 300), HapticFeedback.heavyImpact);
        Future.delayed(const Duration(milliseconds: 600), HapticFeedback.heavyImpact);
      }
    } else if (vibrate && a.priority == 'medium') {
      HapticFeedback.mediumImpact();
    }
    _notify();
  }

  void dismissOverlay() {
    overlay = null;
    notifyListeners();
  }

  // ---- actions ----
  Future<String?> _run(Future<void> Function() f) async {
    try {
      await f();
      await refresh();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> ack(String id) => _run(() => api.ack(id));
  Future<String?> ackAll() => _run(() => api.ackAll());
  Future<String?> decide(String arrivalId, String decision) => _run(() => api.decide(arrivalId, decision));
  Future<String?> simulate(String id) => _run(() => api.simulate(id));
  Future<String?> addPreapproved(Map<String, dynamic> b) => _run(() => api.addPreapproved(b));
  Future<String?> updatePreapproved(String id, Map<String, dynamic> b) => _run(() => api.updatePreapproved(id, b));
  Future<String?> deletePreapproved(String id) => _run(() => api.deletePreapproved(id));
  Future<String?> saveQuiet(String s, String e) => _run(() => api.saveQuietHours(s, e));

  Arrival? arrivalFor(AlertItem a) {
    if (a.arrivalId == null) return null;
    for (final v in visitors) {
      if (v.id == a.arrivalId) return v;
    }
    return null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
