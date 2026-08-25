import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:steam_mobile_authenticator/core/models.dart';
import 'package:steam_mobile_authenticator/core/steam_client.dart';

void main() {
  final account = SteamAccount.fromJson(<String, dynamic>{
    'shared_secret': 'MDEyMzQ1Njc4OUFCQ0RFRg==',
    'identity_secret': 'RkVEQ0JBOTg3NjU0MzIxMA==',
    'account_name': 'test-account',
    'device_id': 'android:00000000-0000-4000-8000-000000000000',
    'Session': <String, dynamic>{
      'SteamID': 76561198000000000,
      'AccessToken': 'synthetic-access-token',
      'RefreshToken': 'synthetic-refresh-token',
      'SessionID': 'synthetic-session-id',
    },
  });
  const confirmation = SteamConfirmation(
    id: '42',
    nonce: 'nonce',
    type: 2,
    typeName: 'Trade',
    creatorId: '100',
    headline: 'Trade with Bob',
    summary: <String>[],
    icon: '',
  );

  test(
    'extracts verified partner and item count from Steam trade details',
    () async {
      final client = SteamClient(
        client: MockClient((request) async {
          expect(request.url.path, '/mobileconf/detailspage/42');
          return http.Response(
            '''{"success":true,"html":"<a data-miniprofile='123'>Bob</a><div class='mobileconf_trade_partner'>Bob</div><div class='trade_item' data-assetid='55555'></div>"}''',
            200,
          );
        }),
      );

      final details = await client.fetchConfirmationDetails(
        account: account,
        confirmation: confirmation,
      );

      expect(details.partnerSteamId, '76561197960265851');
      expect(details.partnerName, 'Bob');
      expect(details.itemCount, 1);
    },
  );
}
