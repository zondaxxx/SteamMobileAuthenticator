import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:steam_mobile_authenticator/core/steam_auth_client.dart';

void main() {
  test('parses an official Steam QR challenge URL without uint64 overflow', () {
    final client = SteamAuthClient();
    addTearDown(client.close);

    final challenge = client.parseQrChallenge(
      'https://s.team/q/2/18446744073709551615',
    );

    expect(challenge.version, 2);
    expect(challenge.clientId, BigInt.parse('18446744073709551615'));
  });

  test('rejects non-Steam QR payloads', () {
    final client = SteamAuthClient();
    addTearDown(client.close);

    expect(
      () => client.parseQrChallenge('https://example.com/login'),
      throwsA(
        isA<SteamAuthException>().having(
          (error) => error.code,
          'code',
          'qr_invalid',
        ),
      ),
    );
  });

  test('reads the nested RSA key returned by Steam', () async {
    final client = SteamAuthClient(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.path,
          '/IAuthenticationService/GetPasswordRSAPublicKey/v1/',
        );
        return http.Response(
          jsonEncode(<String, dynamic>{
            'response': <String, dynamic>{
              'publickey_mod': List<String>.filled(128, 'ff').join(),
              'publickey_exp': '010001',
              'timestamp': '1720000000',
            },
          }),
          200,
        );
      }),
    );

    final credentials = await client.encryptCredentials(
      accountName: 'test-account',
      password: 'correct horse battery staple',
    );

    expect(credentials.password, isNotEmpty);
    expect(credentials.timestamp, '1720000000');
  });

  test('reports a Steam sign-in rate limit precisely', () async {
    final client = SteamAuthClient(
      client: MockClient((_) async => http.Response('{}', 429)),
    );

    await expectLater(
      client.encryptCredentials(accountName: 'test-account', password: 'x'),
      throwsA(
        isA<SteamAuthException>().having(
          (error) => error.code,
          'code',
          'login_rate_limited',
        ),
      ),
    );
  });
}
