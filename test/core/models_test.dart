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
}
