import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steam_mobile_authenticator/data/mafile_importer.dart';

void main() {
  const importer = MaFileImporter();

  test('imports a plain SDA maFile', () async {
    final files = <MaFileBlob>[
      MaFileBlob(
        name: '76561198000000000.maFile',
        bytes: Uint8List.fromList(
          utf8.encode(
            jsonEncode(<String, dynamic>{
              'shared_secret': 'AQIDBAUGBwgJCgsMDQ4PEBESExQ=',
              'identity_secret': 'AQIDBAUGBwgJCgsMDQ4PEBESExQ=',
              'account_name': 'tester',
              'device_id': 'android:test',
              'Session': <String, dynamic>{
                'SteamID': 76561198000000000,
                'AccessToken': 'access',
              },
            }),
          ),
        ),
      ),
    ];

    final accounts = await importer.parse(files);
    expect(accounts, hasLength(1));
    expect(accounts.single.accountName, 'tester');
    expect(accounts.single.steamId, 76561198000000000);
  });

  test('encrypted-looking maFile requires its manifest', () async {
    final files = <MaFileBlob>[
      MaFileBlob(
        name: '1.maFile',
        bytes: Uint8List.fromList(utf8.encode('not-json-ciphertext')),
      ),
    ];

    expect(
      () => importer.parse(files),
      throwsA(
        isA<MaFileImportException>().having(
          (error) => error.code,
          'code',
          'invalid_mafile',
        ),
      ),
    );
  });

  test('imports an SDA AES-256-CBC encrypted maFile', () async {
    const password = 'correct horse battery staple';
    final salt = Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6, 7, 8]);
    final iv = Uint8List.fromList(List<int>.generate(16, (index) => index));
    final plain = utf8.encode(
      jsonEncode(<String, dynamic>{
        'shared_secret': 'AQIDBAUGBwgJCgsMDQ4PEBESExQ=',
        'account_name': 'encrypted',
        'Session': <String, dynamic>{'SteamID': 42},
      }),
    );
    final key = await Pbkdf2(
      macAlgorithm: Hmac.sha1(),
      iterations: 50000,
      bits: 256,
    ).deriveKeyFromPassword(password: password, nonce: salt);
    final secretBox = await AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty)
        .encrypt(plain, secretKey: key, nonce: iv);
    final files = <MaFileBlob>[
      MaFileBlob(
        name: 'manifest.json',
        bytes: Uint8List.fromList(
          utf8.encode(
            jsonEncode(<String, dynamic>{
              'encrypted': true,
              'entries': <Map<String, dynamic>>[
                <String, dynamic>{
                  'filename': '42.maFile',
                  'steamid': 42,
                  'encryption_salt': base64Encode(salt),
                  'encryption_iv': base64Encode(iv),
                },
              ],
            }),
          ),
        ),
      ),
      MaFileBlob(
        name: '42.maFile',
        bytes: Uint8List.fromList(
          utf8.encode(base64Encode(secretBox.cipherText)),
        ),
      ),
    ];

    final accounts = await importer.parse(files, password: password);
    expect(accounts.single.accountName, 'encrypted');
    expect(accounts.single.steamId, 42);
  });
}
