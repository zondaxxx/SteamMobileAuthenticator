import 'dart:convert';

import 'package:http/http.dart' as http;

class SteamTime {
  SteamTime._();

  static int _offsetSeconds = 0;
  static DateTime? _lastSync;

  static int now() =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + _offsetSeconds;

  static int secondsRemaining() => 30 - (now() % 30);

  static double secondsRemainingPrecise() {
    final nowSeconds =
        DateTime.now().millisecondsSinceEpoch / 1000 + _offsetSeconds;
    return 30 - (nowSeconds % 30);
  }

  static Future<void> align({http.Client? client, bool force = false}) async {
    if (!force &&
        _lastSync != null &&
        DateTime.now().difference(_lastSync!) < const Duration(hours: 6)) {
      return;
    }
    final ownedClient = client == null;
    final effectiveClient = client ?? http.Client();
    try {
      final response = await effectiveClient
          .post(
            Uri.https(
              'api.steampowered.com',
              '/ITwoFactorService/QueryTime/v0001',
            ),
            body: const <String, String>{'steamid': '0'},
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) return;
      final decoded = jsonDecode(response.body);
      final value = decoded is Map ? decoded['response'] : null;
      final serverTime = value is Map ? value['server_time'] : null;
      final parsed = int.tryParse(serverTime?.toString() ?? '');
      if (parsed == null) return;
      final local = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _offsetSeconds = parsed - local;
      _lastSync = DateTime.now();
    } catch (_) {
      // Local time is a safe offline fallback. No account data is logged.
    } finally {
      if (ownedClient) effectiveClient.close();
    }
  }
}
