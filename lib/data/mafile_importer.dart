import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../core/models.dart';

class MaFileBlob {
  const MaFileBlob({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

class MaFileImportException implements Exception {
  const MaFileImportException(this.code);

  final String code;

  @override
  String toString() => 'MaFileImportException($code)';
}

class MaFileImporter {
  const MaFileImporter();

  Future<List<SteamAccount>> parse(
    List<MaFileBlob> files, {
    String? password,
  }) async {
    if (files.isEmpty) throw const MaFileImportException('no_files');
    final byName = <String, MaFileBlob>{
      for (final file in files) file.name.toLowerCase(): file,
    };
    final manifestBlob = byName['manifest.json'];
    Map<String, dynamic>? manifest;
    if (manifestBlob != null) {
      manifest = _decodeObject(manifestBlob.bytes, 'invalid_manifest');
    }

    final encrypted = manifest?['encrypted'] == true;
    if (encrypted && (password == null || password.isEmpty)) {
      throw const MaFileImportException('password_required');
    }

    final accounts = <SteamAccount>[];
    if (manifest != null) {
      final rawEntries = manifest['entries'];
      if (rawEntries is List) {
        for (final rawEntry in rawEntries.whereType<Map>()) {
          final entry = Map<String, dynamic>.from(rawEntry);
          final filename = entry['filename']?.toString();
          if (filename == null) continue;
          final blob = byName[filename.toLowerCase()];
          if (blob == null) continue;
          final clearBytes = encrypted
              ? await _decrypt(blob.bytes, entry, password!)
              : blob.bytes;
          accounts.add(_parseAccount(clearBytes));
        }
      }
    }

    if (!encrypted) {
      for (final file in files) {
        final lower = file.name.toLowerCase();
        if (lower == 'manifest.json' || !lower.endsWith('.mafile')) continue;
        final alreadyAdded = accounts.any(
          (account) => _matchesFilename(account, lower),
        );
        if (!alreadyAdded) accounts.add(_parseAccount(file.bytes));
      }
    }

    if (accounts.isEmpty) {
      if (manifest == null &&
          files.any((file) => file.name != 'manifest.json')) {
        throw const MaFileImportException('manifest_required');
      }
      throw const MaFileImportException('no_accounts');
    }
    return accounts;
  }

  bool _matchesFilename(SteamAccount account, String lowerFilename) {
    return account.steamId != 0 &&
        lowerFilename == '${account.steamId}.mafile'.toLowerCase();
  }

  SteamAccount _parseAccount(Uint8List bytes) {
    try {
      return SteamAccount.fromJsonString(utf8.decode(bytes));
    } catch (_) {
      throw const MaFileImportException('invalid_mafile');
    }
  }

  Map<String, dynamic> _decodeObject(Uint8List bytes, String errorCode) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // Converted to a stable error code below.
    }
    throw MaFileImportException(errorCode);
  }

  Future<Uint8List> _decrypt(
    Uint8List cipherText,
    Map<String, dynamic> entry,
    String password,
  ) async {
    final saltSource = entry['encryption_salt']?.toString();
    final ivSource = entry['encryption_iv']?.toString();
    if (saltSource == null || ivSource == null) {
      throw const MaFileImportException('invalid_manifest');
    }
    try {
      final salt = base64Decode(saltSource);
      final iv = base64Decode(ivSource);
      final ciphertextBytes = base64Decode(utf8.decode(cipherText).trim());
      final key = await Pbkdf2(
        macAlgorithm: Hmac.sha1(),
        iterations: 50000,
        bits: 256,
      ).deriveKeyFromPassword(password: password, nonce: salt);
      final clear = await AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty)
          .decrypt(
            SecretBox(ciphertextBytes, nonce: iv, mac: Mac.empty),
            secretKey: key,
          );
      return Uint8List.fromList(clear);
    } catch (_) {
      throw const MaFileImportException('wrong_password');
    }
  }
}
