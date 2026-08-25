import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/models.dart';

class AccountVault {
  AccountVault({FlutterSecureStorage? storage})
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

  static const _indexKey = 'accounts_index_v1';
  static const _accountPrefix = 'account_v1_';
  final FlutterSecureStorage _storage;

  Future<List<SteamAccount>> loadAll() async {
    final ids = await _loadIndex();
    final accounts = <SteamAccount>[];
    for (final id in ids) {
      final source = await _storage.read(key: '$_accountPrefix$id');
      if (source == null) continue;
      try {
        accounts.add(SteamAccount.fromJsonString(source));
      } on FormatException {
        // Ignore a damaged entry but preserve it so recovery remains possible.
      }
    }
    accounts.sort(
      (left, right) => left.accountName.toLowerCase().compareTo(
        right.accountName.toLowerCase(),
      ),
    );
    return accounts;
  }

  Future<void> save(SteamAccount account) async {
    final id = idFor(account);
    await _storage.write(
      key: '$_accountPrefix$id',
      value: account.toJsonString(),
    );
    final ids = await _loadIndex();
    if (!ids.contains(id)) {
      ids.add(id);
      await _saveIndex(ids);
    }
  }

  Future<void> saveAll(Iterable<SteamAccount> accounts) async {
    for (final account in accounts) {
      await save(account);
    }
  }

  Future<void> delete(SteamAccount account) async {
    final id = idFor(account);
    await _storage.delete(key: '$_accountPrefix$id');
    final ids = await _loadIndex();
    ids.remove(id);
    await _saveIndex(ids);
  }

  Future<void> deleteAll() async {
    final ids = await _loadIndex();
    for (final id in ids) {
      await _storage.delete(key: '$_accountPrefix$id');
    }
    await _storage.delete(key: _indexKey);
  }

  String idFor(SteamAccount account) {
    if (account.steamId != 0) return account.steamId.toString();
    return sha256
        .convert(utf8.encode(account.sharedSecret))
        .toString()
        .substring(0, 24);
  }

  Future<List<String>> _loadIndex() async {
    final source = await _storage.read(key: _indexKey);
    if (source == null) return <String>[];
    try {
      final decoded = jsonDecode(source);
      if (decoded is List) {
        return decoded.map((item) => item.toString()).toSet().toList();
      }
    } on FormatException {
      // A fresh index is safer than guessing keys or exposing storage contents.
    }
    return <String>[];
  }

  Future<void> _saveIndex(List<String> ids) {
    ids.sort();
    return _storage.write(key: _indexKey, value: jsonEncode(ids));
  }
}
