class AlertItem {
  final String id;
  final String deviceName;
  final String type; // doorbell | motion | device_offline | device_online
  final String? subType;
  final DateTime time;
  final String priority; // critical | high | medium | low
  final int score;
  final List<String> reasons;
  final String summary;
  final String action;
  final String status; // new | acknowledged
  final String? arrivalId;

  AlertItem({
    required this.id,
    required this.deviceName,
    required this.type,
    required this.subType,
    required this.time,
    required this.priority,
    required this.score,
    required this.reasons,
    required this.summary,
    required this.action,
    required this.status,
    required this.arrivalId,
  });

  bool get isNew => status == 'new';

  factory AlertItem.fromJson(Map<String, dynamic> j) => AlertItem(
        id: j['id'] as String,
        deviceName: (j['deviceName'] ?? '') as String,
        type: (j['type'] ?? '') as String,
        subType: j['subType'] as String?,
        time: DateTime.fromMillisecondsSinceEpoch((j['timestamp'] as num).toInt()),
        priority: (j['priority'] ?? 'low') as String,
        score: ((j['score'] ?? 0) as num).toInt(),
        reasons: ((j['reasons'] ?? []) as List).map((e) => e.toString()).toList(),
        summary: (j['summary'] ?? '') as String,
        action: (j['action'] ?? '') as String,
        status: (j['status'] ?? 'new') as String,
        arrivalId: j['arrivalId'] as String?,
      );
}

class Arrival {
  final String id;
  final String alertId;
  final DateTime time;
  final String deviceName;
  final String visitorName;
  final bool expected;
  final String note;
  final String decision; // pending | auto_approved | approved | denied | wait

  Arrival({
    required this.id,
    required this.alertId,
    required this.time,
    required this.deviceName,
    required this.visitorName,
    required this.expected,
    required this.note,
    required this.decision,
  });

  factory Arrival.fromJson(Map<String, dynamic> j) => Arrival(
        id: j['id'] as String,
        alertId: (j['alertId'] ?? '') as String,
        time: DateTime.fromMillisecondsSinceEpoch((j['timestamp'] as num).toInt()),
        deviceName: (j['deviceName'] ?? '') as String,
        visitorName: (j['visitorName'] ?? 'Unknown visitor') as String,
        expected: (j['expected'] ?? false) as bool,
        note: (j['note'] ?? '') as String,
        decision: (j['decision'] ?? 'pending') as String,
      );
}

class PreApproved {
  final String id;
  final String name;
  final String note;
  final List<int> days; // 0 = Sunday; empty = every day
  final String from;
  final String to;
  final String? validUntil;
  final bool oneTime;
  final bool used;
  final bool active;

  PreApproved({
    required this.id,
    required this.name,
    required this.note,
    required this.days,
    required this.from,
    required this.to,
    required this.validUntil,
    required this.oneTime,
    required this.used,
    required this.active,
  });

  factory PreApproved.fromJson(Map<String, dynamic> j) => PreApproved(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        note: (j['note'] ?? '') as String,
        days: ((j['days'] ?? []) as List).map((e) => (e as num).toInt()).toList(),
        from: (j['from'] ?? '00:00') as String,
        to: (j['to'] ?? '23:59') as String,
        validUntil: j['validUntil'] as String?,
        oneTime: (j['oneTime'] ?? false) as bool,
        used: (j['used'] ?? false) as bool,
        active: (j['active'] ?? true) as bool,
      );
}

class Digest {
  final String headline;
  final Map<String, int> counts;
  final int open;
  final List<AlertItem> attention;

  Digest({required this.headline, required this.counts, required this.open, required this.attention});

  factory Digest.fromJson(Map<String, dynamic> j) => Digest(
        headline: (j['headline'] ?? '') as String,
        counts: ((j['counts'] ?? {}) as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
        open: ((j['open'] ?? 0) as num).toInt(),
        attention: ((j['attention'] ?? []) as List)
            .map((e) => AlertItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static Digest empty() => Digest(headline: 'Connecting...', counts: {}, open: 0, attention: []);
}

class Scenario {
  final String id;
  final String label;
  Scenario(this.id, this.label);
}
