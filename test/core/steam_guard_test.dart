import 'package:flutter_test/flutter_test.dart';
import 'package:steam_mobile_authenticator/core/steam_guard.dart';

void main() {
  const secret = 'AQIDBAUGBwgJCgsMDQ4PEBESExQ=';

  test('generates a Steam Guard code for a fixed independent vector', () {
    expect(SteamGuard.codeFromSecret(secret, 1700000000), '3M9KK');
  });

  test('generates a confirmation hash for a fixed independent vector', () {
    expect(
      SteamGuard.confirmationHash(
        identitySecret: secret,
        unixTimeSeconds: 1700000000,
        tag: 'conf',
      ),
      'YcQ2fHffTJRKwmBpepDsCw04CIE=',
    );
  });

  test('confirmation tags are truncated to 32 bytes', () {
    final long = SteamGuard.confirmationHash(
      identitySecret: secret,
      unixTimeSeconds: 1700000000,
      tag: 'a' * 40,
    );
    final truncated = SteamGuard.confirmationHash(
      identitySecret: secret,
      unixTimeSeconds: 1700000000,
      tag: 'a' * 32,
    );
    expect(long, truncated);
  });
}
