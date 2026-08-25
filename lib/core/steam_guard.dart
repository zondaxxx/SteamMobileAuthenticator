import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'models.dart';

const _steamAlphabet = '23456789BCDFGHJKMNPQRTVWXY';

class SteamGuard {
  const SteamGuard._();

  static String code(SteamAccount account, int unixTimeSeconds) {
    return codeFromSecret(account.sharedSecret, unixTimeSeconds);
  }

  static String codeFromSecret(String base64Secret, int unixTimeSeconds) {
    final secret = base64Decode(base64Secret);
    var time = unixTimeSeconds ~/ 30;
    final timeBytes = Uint8List(8);
    for (var index = 7; index >= 0; index--) {
      timeBytes[index] = time & 0xff;
      time >>= 8;
    }

    final digest = Hmac(sha1, secret).convert(timeBytes).bytes;
    final offset = digest[19] & 0x0f;
    var point =
        ((digest[offset] & 0x7f) << 24) |
        ((digest[offset + 1] & 0xff) << 16) |
        ((digest[offset + 2] & 0xff) << 8) |
        (digest[offset + 3] & 0xff);

    final output = StringBuffer();
    for (var i = 0; i < 5; i++) {
      output.write(_steamAlphabet[point % _steamAlphabet.length]);
      point ~/= _steamAlphabet.length;
    }
    return output.toString();
  }

  static String confirmationHash({
    required String identitySecret,
    required int unixTimeSeconds,
    required String tag,
  }) {
    final secret = base64Decode(identitySecret);
    final safeTag = tag.length > 32 ? tag.substring(0, 32) : tag;
    final tagBytes = utf8.encode(safeTag);
    var time = unixTimeSeconds;
    final payload = Uint8List(8 + tagBytes.length);
    for (var index = 7; index >= 0; index--) {
      payload[index] = time & 0xff;
      time >>= 8;
    }
    payload.setRange(8, payload.length, tagBytes);
    return base64Encode(Hmac(sha1, secret).convert(payload).bytes);
  }
}
