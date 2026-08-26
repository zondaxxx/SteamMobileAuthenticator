import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../core/models.dart';
import 'settings_repository.dart';

class BackupException implements Exception {
  const BackupException(this.code);

  final String code;

  @override
  String toString() => 'BackupException($code)';
}

class BackupPayload {
  const BackupPayload({
    required this.accounts,
    required this.settings,
    required this.history,
    required this.createdAt,
  });

  final List<SteamAccount> accounts;
  final AppSettings settings;
  final List<ActionHistoryEntry> history;
  final DateTime createdAt;
}

class BackupService {
  const BackupService();

  static const format = 'SteamMobileAuthenticatorBackup';
  static const version = 1;
  // OWASP 2024 guidance for PBKDF2-HMAC-SHA256. Older backups remain
  // readable: the iteration count is stored inside the envelope.
  static const iterations = 600000;

  Future<Uint8List> encrypt({
    required List<SteamAccount> accounts,
    required AppSettings settings,
    required List<ActionHistoryEntry> history,
    required String password,
  }) async {
    if (password.length < 8) {
      throw const BackupException('backup_password_short');
    }
    final random = Random.secure();
    final salt = Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
    final nonce = Uint8List.fromList(
      List<int>.generate(12, (_) => random.nextInt(256)),
    );
    final key = await _deriveKey(password, salt);
    final payload = utf8.encode(
      jsonEncode(<String, dynamic>{
        'format': format,
        'version': version,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'accounts': accounts.map((account) => account.toJson()).toList(),
        'settings': settings.toJson(),
        'history': history.map((entry) => entry.toJson()).toList(),
      }),
    );
    final box = await AesGcm.with256bits().encrypt(
      payload,
      secretKey: key,
      nonce: nonce,
    );
    final envelope = <String, dynamic>{
      'format': format,
      'version': version,
      'kdf': <String, dynamic>{
        'name': 'PBKDF2-HMAC-SHA256',
        'iterations': iterations,
        'salt': base64Encode(salt),
      },
      'cipher': <String, dynamic>{
        'name': 'AES-256-GCM',
        'nonce': base64Encode(nonce),
      },
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  Future<BackupPayload> decrypt(Uint8List bytes, String password) async {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map || decoded['format'] != format) {
        throw const BackupException('backup_invalid');
      }
      if (decoded['version'] != version) {
        throw const BackupException('backup_version');
      }
      final kdf = decoded['kdf'];
      final cipher = decoded['cipher'];
      if (kdf is! Map || cipher is! Map) {
        throw const BackupException('backup_invalid');
      }
      final rounds = int.tryParse(kdf['iterations']?.toString() ?? '');
      if (rounds == null || rounds < 100000 || rounds > 2000000) {
        throw const BackupException('backup_invalid');
      }
      final salt = base64Decode(kdf['salt']?.toString() ?? '');
      final nonce = base64Decode(cipher['nonce']?.toString() ?? '');
      final key = await _deriveKey(password, salt, rounds: rounds);
      final clear = await AesGcm.with256bits().decrypt(
        SecretBox(
          base64Decode(decoded['ciphertext']?.toString() ?? ''),
          nonce: nonce,
          mac: Mac(base64Decode(decoded['mac']?.toString() ?? '')),
        ),
        secretKey: key,
      );
      final payload = jsonDecode(utf8.decode(clear));
      if (payload is! Map || payload['format'] != format) {
        throw const BackupException('backup_invalid');
      }
      final rawAccounts = payload['accounts'];
      final rawHistory = payload['history'];
      final rawSettings = payload['settings'];
      if (rawAccounts is! List || rawSettings is! Map) {
        throw const BackupException('backup_invalid');
      }
      return BackupPayload(
        accounts: rawAccounts
            .whereType<Map>()
            .map(
              (item) => SteamAccount.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false),
        settings: AppSettings.fromJson(Map<String, dynamic>.from(rawSettings)),
        history: rawHistory is List
            ? rawHistory
                  .whereType<Map>()
                  .map(
                    (item) => ActionHistoryEntry.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  )
                  .toList(growable: false)
            : <ActionHistoryEntry>[],
        createdAt:
            DateTime.tryParse(payload['createdAt']?.toString() ?? '') ??
            DateTime.now().toUtc(),
      );
    } on BackupException {
      rethrow;
    } on SecretBoxAuthenticationError {
      throw const BackupException('backup_wrong_password');
    } on FormatException {
      throw const BackupException('backup_invalid');
    } catch (_) {
      throw const BackupException('backup_wrong_password');
    }
  }

  Future<SecretKey> _deriveKey(
    String password,
    List<int> salt, {
    int rounds = iterations,
  }) {
    return Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: rounds,
      bits: 256,
    ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
  }
}
