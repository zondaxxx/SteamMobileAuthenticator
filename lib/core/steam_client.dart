import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'models.dart';
import 'steam_guard.dart';
import 'steam_time.dart';

class SteamApiException implements Exception {
  const SteamApiException(this.code);

  final String code;

  @override
  String toString() => 'SteamApiException($code)';
}

class ConfirmationBatch {
  const ConfirmationBatch({required this.account, required this.items});

  final SteamAccount account;
  final List<SteamConfirmation> items;
}

class SteamClient {
  SteamClient({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  static const _mobileClientVersion = '777777 3.6.4';

  SessionHealth sessionHealth(SteamAccount account) {
    final access = account.session.accessToken;
    if (access?.isNotEmpty == true && !_jwtExpiresSoon(access!)) {
      return SessionHealth.healthy;
    }
    final refresh = account.session.refreshToken;
    if (refresh?.isNotEmpty != true) return SessionHealth.missing;
    if (_jwtExpiresSoon(refresh!, grace: Duration.zero)) {
      return SessionHealth.expired;
    }
    return SessionHealth.refreshable;
  }

  Future<SteamAccount> ensureAccessToken(SteamAccount account) async {
    final token = account.session.accessToken;
    if (token?.isNotEmpty == true && !_jwtExpiresSoon(token!)) {
      return account;
    }

    final refreshToken = account.session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty || account.steamId == 0) {
      throw const SteamApiException('session_required');
    }
    if (_jwtExpiresSoon(refreshToken, grace: Duration.zero)) {
      throw const SteamApiException('refresh_expired');
    }

    final response = await _client
        .post(
          Uri.https(
            'api.steampowered.com',
            '/IAuthenticationService/GenerateAccessTokenForApp/v1/',
          ),
          headers: const <String, String>{
            'User-Agent': 'SteamMobileAuthenticator/1.0',
          },
          body: <String, String>{
            'refresh_token': refreshToken,
            'steamid': account.steamId.toString(),
            'renewal_type': '0',
          },
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const SteamApiException('refresh_failed');
    }

    final decoded = jsonDecode(response.body);
    final body = decoded is Map ? decoded['response'] : null;
    if (body is! Map) throw const SteamApiException('refresh_failed');
    final nextAccess = body['access_token']?.toString();
    if (nextAccess == null || nextAccess.isEmpty) {
      throw const SteamApiException('refresh_failed');
    }
    final nextRefresh = body['refresh_token']?.toString();
    return account.copyWith(
      session: account.session.copyWith(
        accessToken: nextAccess,
        refreshToken: nextRefresh?.isNotEmpty == true
            ? nextRefresh
            : account.session.refreshToken,
      ),
    );
  }

  Future<ConfirmationBatch> fetchConfirmations(SteamAccount account) async {
    _validateConfirmationAccount(account);
    await SteamTime.align(client: _client);
    var working = await ensureAccessToken(account);
    if (working.session.sessionId?.isNotEmpty != true) {
      working = working.copyWith(
        session: working.session.copyWith(sessionId: _newSessionId()),
      );
    }
    final uri = _confirmationUri(working, '/mobileconf/getlist', 'conf');
    final response = await _client
        .get(uri, headers: _headers(working))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const SteamApiException('network_error');
    }
    final decoded = _decodeObject(response.body);
    if (decoded['success'] != true) {
      if (decoded['needauth'] == true) {
        throw const SteamApiException('session_required');
      }
      final message = decoded['message']?.toString().toLowerCase() ?? '';
      if (message.contains('nooooo')) {
        throw const SteamApiException('session_required');
      }
      throw const SteamApiException('steam_rejected');
    }
    final rawItems = decoded['conf'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (item) =>
                    SteamConfirmation.fromJson(Map<String, dynamic>.from(item)),
              )
              .where((item) => item.id.isNotEmpty && item.nonce.isNotEmpty)
              .toList(growable: false)
        : const <SteamConfirmation>[];
    return ConfirmationBatch(account: working, items: items);
  }

  Future<SteamConfirmationDetails> fetchConfirmationDetails({
    required SteamAccount account,
    required SteamConfirmation confirmation,
  }) async {
    _validateConfirmationAccount(account);
    var working = await ensureAccessToken(account);
    if (working.session.sessionId?.isNotEmpty != true) {
      working = working.copyWith(
        session: working.session.copyWith(sessionId: _newSessionId()),
      );
    }
    final uri = _confirmationUri(
      working,
      '/mobileconf/detailspage/${confirmation.id}',
      'details',
    );
    final response = await _client
        .get(uri, headers: _headers(working))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const SteamApiException('network_error');
    }
    var html = response.body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        if (decoded['success'] != true) {
          throw const SteamApiException('details_failed');
        }
        html = decoded['html']?.toString() ?? '';
      }
    } on FormatException {
      // Some Steam deployments return HTML directly.
    }
    if (html.trim().isEmpty) {
      throw const SteamApiException('details_failed');
    }
    return _parseConfirmationDetails(html);
  }

  Future<(SteamAccount, SteamProfile)> fetchProfile(
    SteamAccount account,
  ) async {
    final working = await ensureAccessToken(account);
    final token = working.session.accessToken;
    final uri = Uri.https(
      'api.steampowered.com',
      '/ISteamUserOAuth/GetUserSummaries/v0001/',
      <String, String>{
        'access_token': token!,
        'steamids': working.steamId.toString(),
      },
    );
    final response = await _client
        .get(
          uri,
          headers: const <String, String>{
            'User-Agent': 'SteamMobileAuthenticator/1.1',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const SteamApiException('profile_failed');
    }
    final decoded = _decodeObject(response.body);
    final nested = decoded['response'];
    final players =
        decoded['players'] ?? (nested is Map ? nested['players'] : null);
    if (players is! List || players.isEmpty || players.first is! Map) {
      throw const SteamApiException('profile_failed');
    }
    return (
      working,
      SteamProfile.fromJson(Map<String, dynamic>.from(players.first as Map)),
    );
  }

  Future<SteamAccount> actOnConfirmation({
    required SteamAccount account,
    required SteamConfirmation confirmation,
    required bool accept,
  }) async {
    _validateConfirmationAccount(account);
    var working = await ensureAccessToken(account);
    if (working.session.sessionId?.isNotEmpty != true) {
      working = working.copyWith(
        session: working.session.copyWith(sessionId: _newSessionId()),
      );
    }
    final tag = accept ? 'accept' : 'reject';
    final uri = _confirmationUri(
      working,
      '/mobileconf/ajaxop',
      tag,
      extra: <String, String>{
        'op': accept ? 'allow' : 'cancel',
        'cid': confirmation.id,
        'ck': confirmation.nonce,
      },
    );
    final response = await _client
        .get(uri, headers: _headers(working))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const SteamApiException('network_error');
    }
    final decoded = _decodeObject(response.body);
    if (decoded['success'] != true) {
      throw const SteamApiException('action_failed');
    }
    return working;
  }

  void close() {
    if (_ownsClient) _client.close();
  }

  void _validateConfirmationAccount(SteamAccount account) {
    if (account.identitySecret?.isNotEmpty != true) {
      throw const SteamApiException('identity_secret_missing');
    }
    if (account.deviceId?.isNotEmpty != true) {
      throw const SteamApiException('device_id_missing');
    }
    if (account.steamId == 0) {
      throw const SteamApiException('steam_id_missing');
    }
  }

  Uri _confirmationUri(
    SteamAccount account,
    String path,
    String tag, {
    Map<String, String> extra = const <String, String>{},
  }) {
    final timestamp = SteamTime.now();
    final hash = SteamGuard.confirmationHash(
      identitySecret: account.identitySecret!,
      unixTimeSeconds: timestamp,
      tag: tag,
    );
    return Uri.https('steamcommunity.com', path, <String, String>{
      ...extra,
      'p': account.deviceId!,
      'a': account.steamId.toString(),
      'k': hash,
      't': timestamp.toString(),
      'm': 'react',
      'tag': tag,
    });
  }

  Map<String, String> _headers(SteamAccount account) {
    final secureLogin = Uri.encodeComponent(
      '${account.steamId}||${account.session.accessToken ?? ''}',
    );
    return <String, String>{
      'Cookie': <String>[
        'mobileClientVersion=$_mobileClientVersion',
        'mobileClient=android',
        'steamLoginSecure=$secureLogin',
        'sessionid=${account.session.sessionId}',
        'Steam_Language=english',
      ].join('; '),
      'X-Requested-With': 'com.valvesoftware.android.steam.community',
      'User-Agent': 'SteamMobileAuthenticator/1.0',
      'Accept': 'application/json',
    };
  }

  Map<String, dynamic> _decodeObject(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      // Converted to a generic, secret-free error below.
    }
    throw const SteamApiException('invalid_response');
  }

  SteamConfirmationDetails _parseConfirmationDetails(String html) {
    String decodeEntities(String value) => value
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ');

    final miniProfile = RegExp(
      r'''data-miniprofile\s*=\s*["'](\d+)["']''',
      caseSensitive: false,
    ).firstMatch(html);
    final profilePath = RegExp(
      r'(?:steamcommunity\.com)?/profiles/(7656119\d{10})',
      caseSensitive: false,
    ).firstMatch(html);
    String? partnerSteamId = profilePath?.group(1);
    if (partnerSteamId == null && miniProfile != null) {
      final accountId = BigInt.tryParse(miniProfile.group(1)!);
      if (accountId != null) {
        partnerSteamId = (BigInt.parse('76561197960265728') + accountId)
            .toString();
      }
    }

    final nameMatch = RegExp(
      r'''(?:mobileconf_trade_partner|trade_partner[^"']*)[^>]*>(.*?)</''',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(html);
    final partnerName = nameMatch == null
        ? null
        : decodeEntities(
            nameMatch
                .group(1)!
                .replaceAll(RegExp(r'<[^>]+>'), ' ')
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim(),
          );
    final itemMarkers = RegExp(
      r'''class\s*=\s*["'][^"']*(?:trade_item|mobileconf_item)[^"']*["']''',
      caseSensitive: false,
    ).allMatches(html).length;
    final itemIds =
        RegExp(
              r'''(?:data-assetid|id)\s*=\s*["'](?:item)?(\d{5,})["']''',
              caseSensitive: false,
            )
            .allMatches(html)
            .map((match) => match.group(1))
            .whereType<String>()
            .toSet();
    final plainText = decodeEntities(
      html
          .replaceAll(
            RegExp(
              r'<(?:script|style)[^>]*>.*?</(?:script|style)>',
              caseSensitive: false,
              dotAll: true,
            ),
            ' ',
          )
          .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'</(?:div|p|li)>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'<[^>]+>'), ' ')
          .replaceAll(RegExp(r'[ \t]+'), ' ')
          .replaceAll(RegExp(r'\n\s*\n+'), '\n')
          .trim(),
    );
    return SteamConfirmationDetails(
      plainText: plainText,
      itemCount: itemIds.isNotEmpty ? itemIds.length : itemMarkers,
      partnerSteamId: partnerSteamId,
      partnerName: partnerName?.isEmpty == true ? null : partnerName,
      html: html,
    );
  }

  bool _jwtExpiresSoon(
    String token, {
    Duration grace = const Duration(minutes: 5),
  }) {
    final parts = token.split('.');
    if (parts.length < 2) return false;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      if (payload is! Map) return false;
      final exp = int.tryParse(payload['exp']?.toString() ?? '');
      if (exp == null) return false;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return now + grace.inSeconds >= exp;
    } catch (_) {
      return false;
    }
  }

  String _newSessionId() {
    final random = Random.secure();
    const alphabet = '0123456789abcdef';
    return List<String>.generate(
      32,
      (_) => alphabet[random.nextInt(alphabet.length)],
      growable: false,
    ).join();
  }
}
