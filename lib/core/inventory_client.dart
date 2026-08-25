import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';
import 'steam_client.dart';

class InventoryLocation {
  const InventoryLocation(this.appId, this.contextId, this.name);

  final int appId;
  final String contextId;
  final String name;
}

const commonSteamInventories = <InventoryLocation>[
  InventoryLocation(753, '6', 'Steam'),
  InventoryLocation(730, '2', 'Counter-Strike 2'),
  InventoryLocation(570, '2', 'Dota 2'),
  InventoryLocation(440, '2', 'Team Fortress 2'),
];

class InventoryClient {
  InventoryClient({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  final Map<String, (double, String)> _priceCache =
      <String, (double, String)>{};

  Future<InventorySnapshot> fetchAll({
    required SteamAccount account,
    required String currencyCode,
    void Function(int done, int total)? onPriceProgress,
  }) async {
    if (account.steamId == 0) {
      throw const SteamApiException('steam_id_missing');
    }
    final all = <InventoryItem>[];
    var partial = false;
    for (final location in commonSteamInventories) {
      try {
        all.addAll(await _fetchLocation(account, location));
      } on SteamApiException catch (error) {
        if (error.code == 'inventory_private' ||
            error.code == 'inventory_unavailable') {
          partial = true;
          continue;
        }
        rethrow;
      }
    }

    final priceableNames = all
        .where((item) => item.marketable && item.marketHashName.isNotEmpty)
        .map((item) => '${item.appId}\u0000${item.marketHashName}')
        .toSet()
        .toList(growable: false);
    final prices = <String, (double, String)>{};
    var done = 0;
    for (final key in priceableNames) {
      final cachedKey = '$currencyCode\u0000$key';
      final cached = _priceCache[cachedKey];
      if (cached != null) {
        prices[key] = cached;
        done++;
        onPriceProgress?.call(done, priceableNames.length);
        continue;
      }
      final separator = key.indexOf('\u0000');
      final appId = int.parse(key.substring(0, separator));
      final name = key.substring(separator + 1);
      try {
        final price = await _fetchPrice(
          appId: appId,
          marketHashName: name,
          currencyCode: currencyCode,
        );
        if (price != null) {
          prices[key] = price;
          _priceCache[cachedKey] = price;
        } else {
          partial = true;
        }
      } on SteamApiException catch (error) {
        partial = true;
        if (error.code == 'market_rate_limited') break;
      }
      done++;
      onPriceProgress?.call(done, priceableNames.length);
      if (done < priceableNames.length) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    }

    final valuedItems = <InventoryItem>[
      for (final item in all)
        if (prices['${item.appId}\u0000${item.marketHashName}']
            case final price?)
          item.copyWith(price: price.$1, priceText: price.$2)
        else
          item,
    ];
    final total = valuedItems.fold<double>(
      0,
      (sum, item) => sum + (item.totalPrice ?? 0),
    );
    final totalAssets = valuedItems.fold<int>(
      0,
      (sum, item) => sum + item.amount,
    );
    final valuedAssets = valuedItems
        .where((item) => item.price != null)
        .fold<int>(0, (sum, item) => sum + item.amount);
    return InventorySnapshot(
      items: valuedItems,
      currencyCode: currencyCode,
      totalValue: total,
      totalAssets: totalAssets,
      valuedAssets: valuedAssets,
      updatedAt: DateTime.now(),
      partial: partial || valuedAssets < totalAssets,
    );
  }

  Future<List<InventoryItem>> _fetchLocation(
    SteamAccount account,
    InventoryLocation location,
  ) async {
    final result = <InventoryItem>[];
    String? startAssetId;
    do {
      final query = <String, String>{'l': 'english', 'count': '2000'};
      if (startAssetId != null) query['start_assetid'] = startAssetId;
      final uri = Uri.https(
        'steamcommunity.com',
        '/inventory/${account.steamId}/${location.appId}/${location.contextId}',
        query,
      );
      final response = await _client
          .get(uri, headers: _inventoryHeaders(account))
          .timeout(const Duration(seconds: 25));
      if (response.statusCode == 403) {
        throw const SteamApiException('inventory_private');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const SteamApiException('inventory_unavailable');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['success'] != 1) {
        throw const SteamApiException('inventory_unavailable');
      }
      final descriptions = <String, Map<String, dynamic>>{};
      final rawDescriptions = decoded['descriptions'];
      if (rawDescriptions is List) {
        for (final value in rawDescriptions.whereType<Map>()) {
          final description = Map<String, dynamic>.from(value);
          final key =
              '${description['classid']}_${description['instanceid'] ?? '0'}';
          descriptions[key] = description;
        }
      }
      final assets = decoded['assets'];
      if (assets is List) {
        for (final value in assets.whereType<Map>()) {
          final asset = Map<String, dynamic>.from(value);
          final classId = asset['classid']?.toString() ?? '';
          final instanceId = asset['instanceid']?.toString() ?? '0';
          final description = descriptions['${classId}_$instanceId'];
          if (description == null) continue;
          final iconHash = description['icon_url']?.toString() ?? '';
          result.add(
            InventoryItem(
              assetId: asset['assetid']?.toString() ?? '',
              appId: location.appId,
              contextId: location.contextId,
              classId: classId,
              instanceId: instanceId,
              amount: int.tryParse(asset['amount']?.toString() ?? '') ?? 1,
              name:
                  description['market_name']?.toString() ??
                  description['name']?.toString() ??
                  'Steam item',
              marketHashName: description['market_hash_name']?.toString() ?? '',
              iconUrl: iconHash.isEmpty
                  ? ''
                  : 'https://community.cloudflare.steamstatic.com/economy/image/$iconHash/128x128',
              marketable: description['marketable'] == 1,
            ),
          );
        }
      }
      startAssetId = decoded['more_items'] == 1
          ? decoded['last_assetid']?.toString()
          : null;
    } while (startAssetId?.isNotEmpty == true);
    return result;
  }

  Future<(double, String)?> _fetchPrice({
    required int appId,
    required String marketHashName,
    required String currencyCode,
  }) async {
    final currencyId = _currencyId(currencyCode);
    final uri = Uri.https(
      'steamcommunity.com',
      '/market/priceoverview/',
      <String, String>{
        'appid': appId.toString(),
        'currency': currencyId.toString(),
        'market_hash_name': marketHashName,
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
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 429) {
      throw const SteamApiException('market_rate_limited');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['success'] != true) return null;
    final text =
        decoded['lowest_price']?.toString() ??
        decoded['median_price']?.toString();
    if (text == null) return null;
    final number = _parseLocalizedPrice(text);
    return number == null ? null : (number, text);
  }

  Map<String, String> _inventoryHeaders(SteamAccount account) {
    final token = account.session.accessToken;
    if (token?.isNotEmpty != true) {
      return const <String, String>{
        'User-Agent': 'SteamMobileAuthenticator/1.1',
        'Accept': 'application/json',
      };
    }
    final secure = Uri.encodeComponent('${account.steamId}||$token');
    return <String, String>{
      'User-Agent': 'SteamMobileAuthenticator/1.1',
      'Accept': 'application/json',
      'Cookie': 'steamLoginSecure=$secure; Steam_Language=english',
    };
  }

  int _currencyId(String code) => switch (code.toUpperCase()) {
    'USD' => 1,
    'GBP' => 2,
    'EUR' => 3,
    'CHF' => 4,
    'RUB' => 5,
    'PLN' => 6,
    'BRL' => 7,
    'JPY' => 8,
    'NOK' => 9,
    'IDR' => 10,
    'MYR' => 11,
    'PHP' => 12,
    'SGD' => 13,
    'THB' => 14,
    'VND' => 15,
    'KRW' => 16,
    'TRY' => 17,
    'UAH' => 18,
    'MXN' => 19,
    'CAD' => 20,
    'AUD' => 21,
    _ => 1,
  };

  double? _parseLocalizedPrice(String source) {
    var value = source.replaceAll(RegExp(r'[^0-9,.]'), '');
    if (value.isEmpty) return null;
    final lastComma = value.lastIndexOf(',');
    final lastDot = value.lastIndexOf('.');
    final decimalIndex = lastComma > lastDot ? lastComma : lastDot;
    if (decimalIndex >= 0 && value.length - decimalIndex <= 3) {
      final integer = value
          .substring(0, decimalIndex)
          .replaceAll(RegExp(r'[,.]'), '');
      final decimals = value.substring(decimalIndex + 1);
      value = '$integer.$decimals';
    } else {
      value = value.replaceAll(RegExp(r'[,.]'), '');
    }
    return double.tryParse(value);
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
