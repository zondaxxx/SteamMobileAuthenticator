import 'dart:convert';

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String? _asString(Object? value) {
  if (value == null) return null;
  final result = value.toString();
  return result.isEmpty ? null : result;
}

class SteamSession {
  const SteamSession({
    required this.steamId,
    this.accessToken,
    this.refreshToken,
    this.sessionId,
    this.extra = const <String, dynamic>{},
  });

  final int steamId;
  final String? accessToken;
  final String? refreshToken;
  final String? sessionId;
  final Map<String, dynamic> extra;

  factory SteamSession.fromJson(Map<String, dynamic> json) {
    const known = <String>{
      'SteamID',
      'AccessToken',
      'RefreshToken',
      'SessionID',
    };
    final steamLogin = _asString(json['SteamLogin']);
    final legacyAccessToken = steamLogin?.contains('||') == true
        ? steamLogin!.split('||').last
        : null;
    return SteamSession(
      steamId: _asInt(json['SteamID']),
      accessToken:
          _asString(json['AccessToken']) ??
          _asString(json['OAuthToken']) ??
          legacyAccessToken,
      refreshToken: _asString(json['RefreshToken']),
      sessionId: _asString(json['SessionID']),
      extra: Map<String, dynamic>.from(json)
        ..removeWhere((key, _) => known.contains(key)),
    );
  }

  SteamSession copyWith({
    String? accessToken,
    String? refreshToken,
    String? sessionId,
  }) {
    return SteamSession(
      steamId: steamId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      sessionId: sessionId ?? this.sessionId,
      extra: extra,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    ...extra,
    'SteamID': steamId,
    'AccessToken': accessToken,
    'RefreshToken': refreshToken,
    'SessionID': sessionId,
  };
}

class SteamAccount {
  const SteamAccount({
    required this.sharedSecret,
    required this.identitySecret,
    required this.accountName,
    required this.deviceId,
    required this.session,
    required this.raw,
  });

  final String sharedSecret;
  final String? identitySecret;
  final String accountName;
  final String? deviceId;
  final SteamSession session;
  final Map<String, dynamic> raw;

  int get steamId => session.steamId;

  bool get canConfirm =>
      identitySecret?.isNotEmpty == true &&
      deviceId?.isNotEmpty == true &&
      steamId != 0 &&
      session.accessToken?.isNotEmpty == true;

  factory SteamAccount.fromJson(Map<String, dynamic> json) {
    final sessionJson = json['Session'];
    final session = sessionJson is Map
        ? SteamSession.fromJson(Map<String, dynamic>.from(sessionJson))
        : const SteamSession(steamId: 0);
    final secret = _asString(json['shared_secret']);
    if (secret == null) {
      throw const FormatException('maFile does not contain shared_secret');
    }
    final accountName = _asString(json['account_name']);
    return SteamAccount(
      sharedSecret: secret,
      identitySecret: _asString(json['identity_secret']),
      accountName:
          accountName ??
          (session.steamId == 0 ? 'Steam account' : session.steamId.toString()),
      deviceId: _asString(json['device_id']),
      session: session,
      raw: Map<String, dynamic>.from(json),
    );
  }

  factory SteamAccount.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('maFile root must be a JSON object');
    }
    return SteamAccount.fromJson(Map<String, dynamic>.from(decoded));
  }

  SteamAccount copyWith({SteamSession? session}) {
    final nextSession = session ?? this.session;
    final nextRaw = Map<String, dynamic>.from(raw)
      ..['Session'] = nextSession.toJson();
    return SteamAccount(
      sharedSecret: sharedSecret,
      identitySecret: identitySecret,
      accountName: accountName,
      deviceId: deviceId,
      session: nextSession,
      raw: nextRaw,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    ...raw,
    'shared_secret': sharedSecret,
    'identity_secret': identitySecret,
    'account_name': accountName,
    'device_id': deviceId,
    'Session': session.toJson(),
  };

  String toJsonString() => jsonEncode(toJson());
}

class SteamConfirmation {
  const SteamConfirmation({
    required this.id,
    required this.nonce,
    required this.type,
    required this.typeName,
    required this.creatorId,
    required this.headline,
    required this.summary,
    required this.icon,
  });

  final String id;
  final String nonce;
  final int type;
  final String typeName;
  final String creatorId;
  final String headline;
  final List<String> summary;
  final String icon;

  bool get isTrade => type == 2;
  bool get isMarket => type == 3;

  factory SteamConfirmation.fromJson(Map<String, dynamic> json) {
    final rawSummary = json['summary'];
    return SteamConfirmation(
      id: _asString(json['id']) ?? '',
      nonce: _asString(json['nonce']) ?? '',
      type: _asInt(json['type']),
      typeName: _asString(json['type_name']) ?? '',
      creatorId: _asString(json['creator_id']) ?? '',
      headline: _asString(json['headline']) ?? '',
      summary: rawSummary is List
          ? rawSummary.map((item) => item.toString()).toList(growable: false)
          : const <String>[],
      icon: _asString(json['icon']) ?? '',
    );
  }
}
