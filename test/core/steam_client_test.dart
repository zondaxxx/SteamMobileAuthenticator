import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:steam_mobile_authenticator/core/models.dart';
import 'package:steam_mobile_authenticator/core/steam_client.dart';

/// Builds a Steam-shaped JWT whose payload carries [claims].
String fakeJwt(Map<String, Object?> claims) {
  String part(String source) =>
      base64Url.encode(utf8.encode(source)).replaceAll('=', '');
  return '${part('{"typ":"JWT","alg":"EdDSA"}').split('').join()}'
      '.${part(jsonEncode(claims))}.signature';
}

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

  test(
    'public profile fallback parses nickname and avatar without a session',
    () async {
      final client = SteamClient(
        client: MockClient((request) async {
          expect(request.url.host, 'steamcommunity.com');
          expect(request.url.path, '/profiles/76561198000000000/');
          return http.Response(
            '<profile><steamID64>76561198000000000</steamID64>'
            '<steamID><![CDATA[Coolest &amp; Best]]></steamID>'
            '<avatarIcon><![CDATA[http://avatars.example.com/icon.jpg]]></avatarIcon>'
            '<avatarFull><![CDATA[http://avatars.example.com/full.jpg]]></avatarFull>'
            '</profile>',
            200,
          );
        }),
      );

      final profile = await client.fetchPublicProfile(76561198000000000);

      expect(profile.personaName, 'Coolest & Best');
      expect(profile.avatarUrl, 'https://avatars.example.com/full.jpg');
    },
  );

  test('public profile fallback rejects a mismatched steamid page', () async {
    final client = SteamClient(
      client: MockClient(
        (request) async => http.Response(
          '<profile><steamID64>76561198000000001</steamID64></profile>',
          200,
        ),
      ),
    );

    await expectLater(
      client.fetchPublicProfile(76561198000000000),
      throwsA(isA<SteamApiException>()),
    );
  });

  test(
    'refresh reports AccessDenied when Steam answers empty with Eresult 15',
    () async {
      final staleSessionAccount = account.copyWith(
        session: account.session.copyWith(
          accessToken: fakeJwt(<String, Object?>{'exp': 1000000000}),
          refreshToken: fakeJwt(<String, Object?>{'exp': 2000000000}),
        ),
      );
      final client = SteamClient(
        client: MockClient((request) async {
          expect(
            request.url.path.endsWith('GenerateAccessTokenForApp/v1/'),
            isTrue,
          );
          return http.Response(
            '{"response":{}}',
            200,
            headers: <String, String>{'x-eresult': '15'},
          );
        }),
      );

      await expectLater(
        client.ensureAccessToken(staleSessionAccount),
        throwsA(
          isA<SteamApiException>().having(
            (error) => error.code,
            'code',
            'session_denied',
          ),
        ),
      );
    },
  );
}
