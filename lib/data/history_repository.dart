import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/models.dart';

class HistoryRepository {
  HistoryRepository({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(
              resetOnError: false,
              migrateOnAlgorithmChange: true,
              sharedPreferencesName: 'steam_mobile_authenticator',
              preferencesKeyPrefix: 'sma',
            ),
            iOptions: IOSOptions(
              accountName: 'SteamMobileAuthenticator',
              accessibility: KeychainAccessibility.first_unlock_this_device,
              synchronizable: false,
            ),
          );

  static const _key = 'action_history_v1';
  static const _limit = 500;
  final FlutterSecureStorage _storage;

  Future<List<ActionHistoryEntry>> load() async {
    final source = await _storage.read(key: _key);
    if (source == null) return <ActionHistoryEntry>[];
    try {
      final decoded = jsonDecode(source);
      if (decoded is! List) return <ActionHistoryEntry>[];
      final entries = decoded
          .whereType<Map>()
          .map(
            (item) =>
                ActionHistoryEntry.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((entry) => entry.id.isNotEmpty)
          .toList();
      entries.sort((left, right) => right.timestamp.compareTo(left.timestamp));
      return entries;
    } catch (_) {
      return <ActionHistoryEntry>[];
    }
  }

  Future<ActionHistoryEntry> add({
    required SteamAccount account,
    required HistoryAction action,
    required String title,
    String? details,
    String? confirmationId,
    bool success = true,
  }) async {
    final now = DateTime.now();
    final random = Random.secure().nextInt(0x7fffffff);
    final entry = ActionHistoryEntry(
      id: '${now.microsecondsSinceEpoch}-$random',
      timestamp: now,
      steamId: account.steamId,
      accountName: account.accountName,
      action: action,
      title: title,
      details: details,
      confirmationId: confirmationId,
      success: success,
    );
    final entries = await load();
    entries.insert(0, entry);
    await replaceAll(entries.take(_limit));
    return entry;
  }

  Future<void> replaceAll(Iterable<ActionHistoryEntry> entries) {
    final bounded = entries
        .take(_limit)
        .map((entry) => entry.toJson())
        .toList();
    return _storage.write(key: _key, value: jsonEncode(bounded));
  }

  Future<void> clear() => _storage.delete(key: _key);
}
