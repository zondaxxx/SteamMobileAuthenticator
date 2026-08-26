import 'package:flutter_test/flutter_test.dart';
import 'package:steam_mobile_authenticator/app_controller.dart';
import 'package:steam_mobile_authenticator/core/models.dart';
import 'package:steam_mobile_authenticator/core/steam_client.dart';

void main() {
  final account = SteamAccount.fromJson(<String, dynamic>{
    'shared_secret': 'MDEyMzQ1Njc4OUFCQ0RFRg==',
    'identity_secret': 'RkVEQ0JBOTg3NjU0MzIxMA==',
    'account_name': 'session-test',
    'device_id': 'android:00000000-0000-4000-8000-000000000000',
    'Session': <String, dynamic>{
      'SteamID': 76561198000000000,
      'RefreshToken': 'refresh-token',
    },
  });

  test('metadata check preserves a safe session failure reason', () async {
    final controller = AppController(
      steamClient: _FailingSteamClient('refresh_failed'),
    )..accounts = <SteamAccount>[account];

    await controller.refreshAccountMetadata();

    expect(controller.sessionHealth[account.steamId], SessionHealth.error);
    expect(controller.sessionErrorCodes[account.steamId], 'refresh_failed');
  });

  test('expired refresh token gets an actionable status', () async {
    final controller = AppController(
      steamClient: _FailingSteamClient('refresh_expired'),
    )..accounts = <SteamAccount>[account];

    await controller.refreshAccountMetadata();

    expect(controller.sessionHealth[account.steamId], SessionHealth.expired);
    expect(controller.sessionErrorCodes[account.steamId], 'refresh_expired');
  });
}

class _FailingSteamClient extends SteamClient {
  _FailingSteamClient(this.code);

  final String code;

  @override
  SessionHealth sessionHealth(SteamAccount account) =>
      SessionHealth.refreshable;

  @override
  Future<(SteamAccount, SteamProfile)> fetchProfile(SteamAccount account) =>
      Future<(SteamAccount, SteamProfile)>.error(SteamApiException(code));

  @override
  Future<SteamProfile> fetchPublicProfile(int steamId) =>
      Future<SteamProfile>.error(const SteamApiException('profile_failed'));
}
