import 'dart:convert';

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String? _asString(Object? value) {
  if (value == null) return null;
  final result = value.toString().trim();
  return result.isEmpty ? null : result;
}

/// SDA maFiles produced by different tools sometimes carry stray whitespace or
/// line breaks inside base64 secrets, which makes base64Decode throw later.
String _asSecret(Object? value) => (value?.toString() ?? '').trim();

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
    final secret = _asSecret(json['shared_secret']);
    if (secret.isEmpty) {
      throw const FormatException('maFile does not contain shared_secret');
    }
    final accountName = _asString(json['account_name']);
    return SteamAccount(
      sharedSecret: secret,
      identitySecret: _asSecret(json['identity_secret']).isEmpty
          ? null
          : _asSecret(json['identity_secret']),
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

  /// Last profile data seen for this account, used to render the nickname and
  /// avatar instantly and while no fresh Steam session is available.
  SteamProfile? get cachedProfile {
    final cached = raw['cached_profile'];
    if (cached is! Map) return null;
    try {
      return SteamProfile.fromJson(Map<String, dynamic>.from(cached));
    } on Exception {
      return null;
    }
  }

  SteamAccount withCachedProfile(SteamProfile profile) {
    final nextRaw = Map<String, dynamic>.from(raw)
      ..['cached_profile'] = profile.toJson();
    return SteamAccount(
      sharedSecret: sharedSecret,
      identitySecret: identitySecret,
      accountName: accountName,
      deviceId: deviceId,
      session: session,
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

class SteamConfirmationDetails {
  const SteamConfirmationDetails({
    required this.plainText,
    required this.itemCount,
    this.partnerSteamId,
    this.partnerName,
    this.html,
  });

  final String plainText;
  final int itemCount;
  final String? partnerSteamId;
  final String? partnerName;
  final String? html;

  bool get hasVerifiedPartner => partnerSteamId?.isNotEmpty == true;
}

class SteamProfile {
  const SteamProfile({
    required this.steamId,
    required this.personaName,
    this.avatarUrl,
    this.profileUrl,
    this.lastLogoff,
  });

  final int steamId;
  final String personaName;
  final String? avatarUrl;
  final String? profileUrl;
  final DateTime? lastLogoff;

  factory SteamProfile.fromJson(Map<String, dynamic> json) => SteamProfile(
    steamId: _asInt(json['steamid']),
    personaName: _asString(json['personaname']) ?? 'Steam user',
    avatarUrl:
        _asString(json['avatarfull']) ??
        _asString(json['avatarmedium']) ??
        _asString(json['avatar']),
    profileUrl: _asString(json['profileurl']),
    lastLogoff: _asInt(json['lastlogoff']) == 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            _asInt(json['lastlogoff']) * 1000,
            isUtc: true,
          ).toLocal(),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'steamid': steamId,
    'personaname': personaName,
    'avatarfull': avatarUrl,
    'profileurl': profileUrl,
    'lastlogoff': lastLogoff?.toUtc().millisecondsSinceEpoch == null
        ? null
        : lastLogoff!.toUtc().millisecondsSinceEpoch ~/ 1000,
  };
}

enum SessionHealth { healthy, refreshable, expired, missing, checking, error }

class InventoryItem {
  const InventoryItem({
    required this.assetId,
    required this.appId,
    required this.contextId,
    required this.classId,
    required this.instanceId,
    required this.amount,
    required this.name,
    required this.marketHashName,
    required this.iconUrl,
    required this.marketable,
    this.price,
    this.priceText,
  });

  final String assetId;
  final int appId;
  final String contextId;
  final String classId;
  final String instanceId;
  final int amount;
  final String name;
  final String marketHashName;
  final String iconUrl;
  final bool marketable;
  final double? price;
  final String? priceText;

  double? get totalPrice => price == null ? null : price! * amount;

  InventoryItem copyWith({double? price, String? priceText}) => InventoryItem(
    assetId: assetId,
    appId: appId,
    contextId: contextId,
    classId: classId,
    instanceId: instanceId,
    amount: amount,
    name: name,
    marketHashName: marketHashName,
    iconUrl: iconUrl,
    marketable: marketable,
    price: price ?? this.price,
    priceText: priceText ?? this.priceText,
  );
}

class InventorySnapshot {
  const InventorySnapshot({
    required this.items,
    required this.currencyCode,
    required this.totalValue,
    required this.totalAssets,
    required this.valuedAssets,
    required this.updatedAt,
    this.partial = false,
  });

  final List<InventoryItem> items;
  final String currencyCode;
  final double totalValue;
  final int totalAssets;
  final int valuedAssets;
  final DateTime updatedAt;
  final bool partial;
}

enum HistoryAction {
  confirmationSeen,
  accepted,
  declined,
  autoAccepted,
  autoSkipped,
  qrApproved,
  authenticatorAdded,
  backupCreated,
  backupRestored,
  error,
}

class ActionHistoryEntry {
  const ActionHistoryEntry({
    required this.id,
    required this.timestamp,
    required this.steamId,
    required this.accountName,
    required this.action,
    required this.title,
    this.details,
    this.confirmationId,
    this.success = true,
  });

  final String id;
  final DateTime timestamp;
  final int steamId;
  final String accountName;
  final HistoryAction action;
  final String title;
  final String? details;
  final String? confirmationId;
  final bool success;

  factory ActionHistoryEntry.fromJson(Map<String, dynamic> json) =>
      ActionHistoryEntry(
        id: _asString(json['id']) ?? '',
        timestamp:
            DateTime.tryParse(_asString(json['timestamp']) ?? '')?.toLocal() ??
            DateTime.fromMillisecondsSinceEpoch(0),
        steamId: _asInt(json['steamId']),
        accountName: _asString(json['accountName']) ?? 'Steam account',
        action: HistoryAction.values.firstWhere(
          (value) => value.name == _asString(json['action']),
          orElse: () => HistoryAction.error,
        ),
        title: _asString(json['title']) ?? '',
        details: _asString(json['details']),
        confirmationId: _asString(json['confirmationId']),
        success: json['success'] != false,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'steamId': steamId,
    'accountName': accountName,
    'action': action.name,
    'title': title,
    'details': details,
    'confirmationId': confirmationId,
    'success': success,
  };
}

class QrChallenge {
  const QrChallenge({required this.version, required this.clientId});

  final int version;
  final BigInt clientId;
}

class QrSessionInfo {
  const QrSessionInfo({
    required this.deviceName,
    required this.ip,
    required this.location,
  });

  final String deviceName;
  final String ip;
  final String location;
}

class LoginSession {
  const LoginSession({
    required this.clientId,
    required this.requestId,
    required this.steamId,
    required this.intervalSeconds,
    required this.guardTypes,
  });

  final String clientId;
  final String requestId;
  final int steamId;
  final int intervalSeconds;
  final List<int> guardTypes;
}

class LoginTokens {
  const LoginTokens({
    required this.steamId,
    required this.accessToken,
    required this.refreshToken,
  });

  final int steamId;
  final String accessToken;
  final String refreshToken;
}
