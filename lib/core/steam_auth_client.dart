import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart';

import 'models.dart';
import 'steam_guard.dart';
import 'steam_time.dart';

class SteamAuthException implements Exception {
  const SteamAuthException(this.code);

  final String code;

  @override
  String toString() => 'SteamAuthException($code)';
}

class EncryptedCredentials {
  const EncryptedCredentials(this.password, this.timestamp);

  final String password;
  final String timestamp;
}

class SteamAuthClient {
  SteamAuthClient({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  static const _authPath = '/IAuthenticationService';

  QrChallenge parseQrChallenge(String source) {
    final match = RegExp(r'/q/(\d+)/(\d+)').firstMatch(source.trim());
    final version = int.tryParse(match?.group(1) ?? '');
    final clientId = BigInt.tryParse(match?.group(2) ?? '');
    if (version == null || clientId == null) {
      throw const SteamAuthException('qr_invalid');
    }
    return QrChallenge(version: version, clientId: clientId);
  }

  Future<QrSessionInfo> getQrSessionInfo({
    required QrChallenge challenge,
    required String accessToken,
  }) async {
    final decoded = await _postApi(
      '$_authPath/GetAuthSessionInfo/v1/',
      <String, String>{'client_id': challenge.clientId.toString()},
      accessToken: accessToken,
    );
    final location = <String>[
      decoded['city']?.toString() ?? '',
      decoded['state']?.toString() ?? '',
      decoded['country']?.toString() ?? '',
    ].where((part) => part.isNotEmpty).join(', ');
    return QrSessionInfo(
      deviceName:
          decoded['device_friendly_name']?.toString() ?? 'Unknown device',
      ip: decoded['ip']?.toString() ?? '',
      location: location,
    );
  }

  Future<void> approveQr({
    required QrChallenge challenge,
    required SteamAccount account,
  }) async {
    final token = account.session.accessToken;
    if (token?.isNotEmpty != true || account.steamId == 0) {
      throw const SteamAuthException('session_required');
    }
    final bytes = Uint8List(18);
    bytes[0] = challenge.version & 0xff;
    bytes[1] = (challenge.version >> 8) & 0xff;
    _writeUint64Le(bytes, 2, challenge.clientId);
    _writeUint64Le(bytes, 10, BigInt.from(account.steamId));
    final signature = base64Encode(
      Hmac(sha256, base64Decode(account.sharedSecret)).convert(bytes).bytes,
    );
    await _postApi(
      '$_authPath/UpdateAuthSessionWithMobileConfirmation/v1/',
      <String, String>{
        'version': challenge.version.toString(),
        'client_id': challenge.clientId.toString(),
        'steamid': account.steamId.toString(),
        'signature': signature,
        'confirm': '1',
        'persistence': '1',
      },
      accessToken: token,
    );
  }

  Future<EncryptedCredentials> encryptCredentials({
    required String accountName,
    required String password,
  }) async {
    late final http.Response response;
    try {
      response = await _client
          .get(
            Uri.https(
              'api.steampowered.com',
              '$_authPath/GetPasswordRSAPublicKey/v1/',
              <String, String>{'account_name': accountName},
            ),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const SteamAuthException('login_network');
    } on http.ClientException {
      throw const SteamAuthException('login_network');
    }
    final decoded = _responseObject(response, 'login_invalid_response');
    final nested = decoded['response'];
    if (nested is! Map) {
      throw const SteamAuthException('login_invalid_response');
    }
    final key = Map<String, dynamic>.from(nested);
    final modulus = key['publickey_mod']?.toString();
    final exponent = key['publickey_exp']?.toString();
    final timestamp = key['timestamp']?.toString();
    if (modulus == null || exponent == null || timestamp == null) {
      throw const SteamAuthException('login_invalid_response');
    }
    try {
      final publicKey = RSAPublicKey(
        BigInt.parse(modulus, radix: 16),
        BigInt.parse(exponent, radix: 16),
      );
      final cipher = PKCS1Encoding(RSAEngine())
        ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
      final encrypted = cipher.process(
        Uint8List.fromList(utf8.encode(password)),
      );
      return EncryptedCredentials(base64Encode(encrypted), timestamp);
    } catch (_) {
      throw const SteamAuthException('login_encryption_failed');
    }
  }

  Future<LoginSession> beginLogin({
    required String accountName,
    required EncryptedCredentials credentials,
    String deviceName = 'Steam Mobile Authenticator',
  }) async {
    final response = await _postApi(
      '$_authPath/BeginAuthSessionViaCredentials/v1/',
      <String, String>{
        'account_name': accountName,
        'encrypted_password': credentials.password,
        'encryption_timestamp': credentials.timestamp,
        'remember_login': 'true',
        'persistence': '1',
        'platform_type': '3',
        'device_friendly_name': deviceName,
        'website_id': 'Mobile',
      },
      errorCode: 'login_bad_credentials',
    );
    final confirmations = response['allowed_confirmations'];
    return LoginSession(
      clientId: response['client_id']?.toString() ?? '',
      requestId: response['request_id']?.toString() ?? '',
      steamId: int.tryParse(response['steamid']?.toString() ?? '') ?? 0,
      intervalSeconds:
          (double.tryParse(response['interval']?.toString() ?? '') ?? 5)
              .ceil()
              .clamp(1, 10),
      guardTypes: confirmations is List
          ? confirmations
                .whereType<Map>()
                .map(
                  (item) =>
                      int.tryParse(
                        item['confirmation_type']?.toString() ?? '',
                      ) ??
                      0,
                )
                .where((value) => value != 0)
                .toList(growable: false)
          : const <int>[],
    );
  }

  Future<void> submitGuardCode({
    required LoginSession session,
    required String code,
    required int codeType,
  }) async {
    await _postApi(
      '$_authPath/UpdateAuthSessionWithSteamGuardCode/v1/',
      <String, String>{
        'client_id': session.clientId,
        'steamid': session.steamId.toString(),
        'code': code.trim(),
        'code_type': codeType.toString(),
      },
      errorCode: 'login_bad_guard',
    );
  }

  Future<LoginTokens> pollLogin(LoginSession session) async {
    var clientId = session.clientId;
    var consecutiveFailures = 0;
    for (var attempt = 0; attempt < 40; attempt++) {
      late final Map<String, dynamic> response;
      try {
        response = await _postApi(
          '$_authPath/PollAuthSessionStatus/v1/',
          <String, String>{
            'client_id': clientId,
            'request_id': session.requestId,
          },
          errorCode: 'login_poll_failed',
        );
        consecutiveFailures = 0;
      } on SteamAuthException {
        // A single failed request (network hiccup, edge challenge) must not
        // abort the whole sign-in; Steam keeps the session open server-side.
        consecutiveFailures++;
        if (consecutiveFailures >= 4) rethrow;
        await Future<void>.delayed(Duration(seconds: session.intervalSeconds));
        continue;
      }
      final nextId = response['new_client_id']?.toString();
      if (nextId?.isNotEmpty == true && nextId != '0') clientId = nextId!;
      final refresh = response['refresh_token']?.toString();
      if (refresh?.isNotEmpty == true) {
        final access = response['access_token']?.toString();
        if (access?.isNotEmpty != true) {
          throw const SteamAuthException('login_poll_failed');
        }
        return LoginTokens(
          steamId: session.steamId,
          accessToken: access!,
          refreshToken: refresh!,
        );
      }
      await Future<void>.delayed(Duration(seconds: session.intervalSeconds));
    }
    throw const SteamAuthException('login_timeout');
  }

  Future<SteamAccount> beginEnrollment({
    required String accountName,
    required LoginTokens tokens,
  }) async {
    final deviceId = 'android:${_uuid()}';
    final response = await _postApi(
      '/ITwoFactorService/AddAuthenticator/v1/',
      <String, String>{
        'steamid': tokens.steamId.toString(),
        'authenticator_type': '1',
        'device_identifier': deviceId,
        'sms_phone_id': '1',
        'version': '2',
      },
      accessToken: tokens.accessToken,
      errorCode: 'enroll_failed',
    );
    final status = int.tryParse(response['status']?.toString() ?? '') ?? -1;
    if (status == 2) throw const SteamAuthException('enroll_phone_required');
    if (status == 29) {
      throw const SteamAuthException('enroll_authenticator_present');
    }
    if (status != 1) throw const SteamAuthException('enroll_failed');
    final raw = Map<String, dynamic>.from(response)
      ..['account_name'] = accountName
      ..['device_id'] = deviceId
      ..['fully_enrolled'] = false
      ..['Session'] = <String, dynamic>{
        'SteamID': tokens.steamId,
        'AccessToken': tokens.accessToken,
        'RefreshToken': tokens.refreshToken,
        'SessionID': _sessionId(),
      };
    try {
      return SteamAccount.fromJson(raw);
    } on FormatException {
      throw const SteamAuthException('enroll_failed');
    }
  }

  Future<SteamAccount> finalizeEnrollment({
    required SteamAccount draft,
    required String smsCode,
  }) async {
    final token = draft.session.accessToken;
    if (token?.isNotEmpty != true) {
      throw const SteamAuthException('session_required');
    }
    await SteamTime.align(client: _client);
    for (var attempt = 0; attempt <= 30; attempt++) {
      final timestamp = SteamTime.now();
      final response = await _postApi(
        '/ITwoFactorService/FinalizeAddAuthenticator/v1/',
        <String, String>{
          'steamid': draft.steamId.toString(),
          'authenticator_code': SteamGuard.code(draft, timestamp),
          'authenticator_time': timestamp.toString(),
          'activation_code': smsCode.trim(),
          'validate_sms_code': '1',
        },
        accessToken: token,
        errorCode: 'enroll_finalize_failed',
      );
      final status = int.tryParse(response['status']?.toString() ?? '') ?? -1;
      if (status == 89) {
        throw const SteamAuthException('enroll_bad_sms');
      }
      if (response['success'] == true) {
        final raw = Map<String, dynamic>.from(draft.raw)
          ..['fully_enrolled'] = true
          ..['Session'] = draft.session.toJson();
        return SteamAccount.fromJson(raw);
      }
      if (response['want_more'] != true) {
        throw const SteamAuthException('enroll_finalize_failed');
      }
    }
    throw const SteamAuthException('enroll_time_failed');
  }

  Future<Map<String, dynamic>> _postApi(
    String path,
    Map<String, String> body, {
    String? accessToken,
    bool unwrapResponse = true,
    String errorCode = 'steam_auth_failed',
  }) async {
    final query = accessToken == null
        ? null
        : <String, String>{'access_token': accessToken};
    late final http.Response response;
    try {
      response = await _client
          .post(
            Uri.https('api.steampowered.com', path, query),
            headers: _headers,
            body: body,
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const SteamAuthException('login_network');
    } on http.ClientException {
      throw const SteamAuthException('login_network');
    }
    final decoded = _responseObject(response, errorCode);
    if (!unwrapResponse) return decoded;
    final nested = decoded['response'];
    // An empty payload combined with a failing EResult means Steam rejected
    // the request without an HTTP error — surface the real reason.
    if (nested is! Map || nested.isEmpty) {
      final eresult = int.tryParse(response.headers['x-eresult'] ?? '');
      if (eresult != null && eresult != 1) {
        throw SteamAuthException(_mapEresult(eresult, errorCode));
      }
      if (nested is! Map) throw SteamAuthException(errorCode);
      // Eresult 1 with an empty payload is a valid "nothing yet" answer.
      return const <String, dynamic>{};
    }
    return Map<String, dynamic>.from(nested);
  }

  String _mapEresult(int eresult, String fallback) => switch (eresult) {
    5 => 'login_bad_credentials',
    15 => 'session_denied',
    84 => 'login_rate_limited',
    _ => fallback,
  };

  Map<String, dynamic> _responseObject(http.Response response, String code) {
    if (response.statusCode == 429) {
      throw const SteamAuthException('login_rate_limited');
    }
    if (response.statusCode >= 500) {
      throw const SteamAuthException('login_unavailable');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SteamAuthException(code);
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // Converted to the secret-free error below.
    }
    throw SteamAuthException(code);
  }

  void _writeUint64Le(Uint8List target, int offset, BigInt value) {
    var working = value;
    for (var index = 0; index < 8; index++) {
      target[offset + index] = (working & BigInt.from(0xff)).toInt();
      working >>= 8;
    }
  }

  String _uuid() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  String _sessionId() {
    const alphabet = '0123456789abcdef';
    final random = Random.secure();
    return List<String>.generate(
      32,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }

  static const _headers = <String, String>{
    'User-Agent': 'SteamMobileAuthenticator/1.1',
    'Accept': 'application/json',
  };

  void close() {
    if (_ownsClient) _client.close();
  }
}
