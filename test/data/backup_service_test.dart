import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steam_mobile_authenticator/core/models.dart';
import 'package:steam_mobile_authenticator/data/backup_service.dart';
import 'package:steam_mobile_authenticator/data/settings_repository.dart';

void main() {
  const service = BackupService();
  final account = SteamAccount.fromJson(<String, dynamic>{
    'shared_secret': 'MDEyMzQ1Njc4OUFCQ0RFRg==',
    'identity_secret': 'RkVEQ0JBOTg3NjU0MzIxMA==',
    'account_name': 'test-account',
    'device_id': 'android:00000000-0000-4000-8000-000000000000',
    'Session': <String, dynamic>{
      'SteamID': 76561198000000000,
      'AccessToken': 'access',
      'RefreshToken': 'refresh',
      'SessionID': 'session',
    },
  });

  test('encrypted backup round-trips accounts, settings and history', () async {
    final bytes = await service.encrypt(
      accounts: <SteamAccount>[account],
      settings: const AppSettings(
        themeMode: ThemeMode.dark,
        localeCode: 'ru',
        allowedPartnerSteamIds: <String>['76561198000000001'],
      ),
      history: <ActionHistoryEntry>[
        ActionHistoryEntry(
          id: 'history-1',
          timestamp: DateTime.utc(2026, 8, 25),
          steamId: account.steamId,
          accountName: account.accountName,
          action: HistoryAction.accepted,
          title: 'Trade accepted',
        ),
      ],
      password: 'correct horse battery staple',
    );

    final restored = await service.decrypt(
      bytes,
      'correct horse battery staple',
    );
    expect(restored.accounts.single.accountName, 'test-account');
    expect(restored.accounts.single.sharedSecret, account.sharedSecret);
    expect(restored.settings.themeMode, ThemeMode.dark);
    expect(restored.settings.allowedPartnerSteamIds, <String>[
      '76561198000000001',
    ]);
    expect(restored.history.single.action, HistoryAction.accepted);
  });

  test('wrong password and tampering are rejected', () async {
    final bytes = await service.encrypt(
      accounts: <SteamAccount>[account],
      settings: const AppSettings(),
      history: const <ActionHistoryEntry>[],
      password: 'a very strong password',
    );

    await expectLater(
      service.decrypt(bytes, 'another password'),
      throwsA(
        isA<BackupException>().having(
          (error) => error.code,
          'code',
          'backup_wrong_password',
        ),
      ),
    );

    final damaged = Uint8List.fromList(bytes);
    damaged[damaged.length - 8] ^= 1;
    await expectLater(
      service.decrypt(damaged, 'a very strong password'),
      throwsA(isA<BackupException>()),
    );
  });
}
