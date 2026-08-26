import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:steam_mobile_authenticator/core/models.dart';

void main() {
  test('maFile parser preserves unknown fields on round trip', () {
    final account = SteamAccount.fromJson(<String, dynamic>{
      'shared_secret': 'AQIDBA==',
      'identity_secret': 'BQYHCA==',
      'account_name': 'tester',
      'device_id': 'android:test',
      'future_field': <String, dynamic>{'value': 7},
      'Session': <String, dynamic>{
        'SteamID': '76561198000000000',
        'AccessToken': 'access',
        'RefreshToken': 'refresh',
        'SessionID': 'session',
        'LegacyToken': 'preserved',
      },
    });

    final encoded = jsonDecode(account.toJsonString()) as Map<String, dynamic>;
    expect(account.steamId, 76561198000000000);
    expect(encoded['future_field'], <String, dynamic>{'value': 7});
    expect(
      (encoded['Session'] as Map<String, dynamic>)['LegacyToken'],
      'preserved',
    );
  });

  test('maFile without shared_secret is rejected', () {
    expect(
      () => SteamAccount.fromJson(<String, dynamic>{}),
      throwsFormatException,
    );
  });

  test('base64 secrets are normalized from messy maFiles', () {
    final account = SteamAccount.fromJson(<String, dynamic>{
      'shared_secret': ' AQIDBA==\n',
      'identity_secret': ' BQYHCA== ',
      'account_name': 'tester',
      'Session': <String, dynamic>{'SteamID': 76561198000000000},
    });

    expect(account.sharedSecret, 'AQIDBA==');
    expect(account.identitySecret, 'BQYHCA==');
    expect(() => base64Decode(account.sharedSecret), returnsNormally);
  });

  test('cached profile survives a round trip through the vault JSON', () {
    const profile = SteamProfile(
      steamId: 76561198000000000,
      personaName: 'Tester',
      avatarUrl: 'https://avatars.example.com/full.jpg',
    );
    final account = SteamAccount.fromJson(<String, dynamic>{
      'shared_secret': 'AQIDBA==',
      'account_name': 'tester',
      'Session': <String, dynamic>{'SteamID': 76561198000000000},
    }).withCachedProfile(profile);

    final restored = SteamAccount.fromJsonString(account.toJsonString());

    expect(restored.cachedProfile?.personaName, 'Tester');
    expect(
      restored.cachedProfile?.avatarUrl,
      'https://avatars.example.com/full.jpg',
    );
    expect(restored.cachedProfile?.steamId, 76561198000000000);
  });
}
