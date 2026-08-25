import 'package:flutter_test/flutter_test.dart';
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
}
