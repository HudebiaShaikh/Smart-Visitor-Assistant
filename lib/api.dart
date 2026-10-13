import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiClient {
  String baseUrl;
  String apiKey;

  ApiClient({required this.baseUrl, this.apiKey = ''});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (apiKey.isNotEmpty) 'x-api-key': apiKey,
      };

  Uri _uri(String path) => Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}$path');

  Future<dynamic> _send(String method, String path, {Object? body}) async {
    final uri = _uri(path);
    late http.Response res;
    try {
      switch (method) {
        case 'POST':
          res = await http.post(uri, headers: _headers, body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 10));
          break;
        case 'PUT':
          res = await http.put(uri, headers: _headers, body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 10));
          break;
        case 'DELETE':
          res = await http.delete(uri, headers: _headers).timeout(const Duration(seconds: 10));
          break;
        default:
          res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
      }
    } on TimeoutException {
      throw ApiException('Server did not answer. Check the address in Settings.');
    } catch (_) {
      throw ApiException('Cannot reach the server. Check the address in Settings.');
    }
    if (res.statusCode == 204) return null;
    final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 400) {
      final msg = decoded is Map && decoded['error'] != null ? decoded['error'].toString() : 'Error ${res.statusCode}';
      throw ApiException(msg);
    }
    return decoded;
  }

  Future<Map<String, dynamic>> status() async => (await _send('GET', '/api/status')) as Map<String, dynamic>;

  Future<List<AlertItem>> alerts({String sort = 'time'}) async {
    final j = (await _send('GET', '/api/alerts?limit=200&sort=$sort')) as List;
    return j.map((e) => AlertItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Digest> digest() async => Digest.fromJson((await _send('GET', '/api/digest')) as Map<String, dynamic>);

  Future<void> ack(String id) => _send('POST', '/api/alerts/$id/ack');

  Future<void> ackAll() => _send('POST', '/api/alerts/ack-all');

  Future<List<Arrival>> visitors() async {
    final j = (await _send('GET', '/api/visitors?limit=200')) as List;
    return j.map((e) => Arrival.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> decide(String arrivalId, String decision) =>
      _send('POST', '/api/visitors/$arrivalId/decision', body: {'decision': decision});

  Future<List<PreApproved>> preapproved() async {
    final j = (await _send('GET', '/api/preapproved')) as List;
    return j.map((e) => PreApproved.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addPreapproved(Map<String, dynamic> body) => _send('POST', '/api/preapproved', body: body);

  Future<void> updatePreapproved(String id, Map<String, dynamic> body) => _send('PUT', '/api/preapproved/$id', body: body);

  Future<void> deletePreapproved(String id) => _send('DELETE', '/api/preapproved/$id');

  Future<void> simulate(String scenario) => _send('POST', '/api/simulate', body: {'scenario': scenario});

  Future<void> saveQuietHours(String start, String end) =>
      _send('PUT', '/api/settings', body: {'quietStart': start, 'quietEnd': end});

  /// Server-Sent Events. Yields (eventName, jsonData). Ends when the connection drops.
  Stream<MapEntry<String, dynamic>> stream() async* {
    final client = http.Client();
    try {
      final req = http.Request('GET', _uri('/api/stream'));
      req.headers['Accept'] = 'text/event-stream';
      if (apiKey.isNotEmpty) req.headers['x-api-key'] = apiKey;
      final res = await client.send(req).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw ApiException('Stream error ${res.statusCode}');

      String event = 'message';
      final lines = res.stream.transform(utf8.decoder).transform(const LineSplitter());
      await for (final line in lines) {
        if (line.startsWith('event:')) {
          event = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          final raw = line.substring(5).trim();
          try {
            yield MapEntry(event, jsonDecode(raw));
          } catch (_) {/* ignore malformed frame */}
          event = 'message';
        }
      }
    } finally {
      client.close();
    }
  }
}
