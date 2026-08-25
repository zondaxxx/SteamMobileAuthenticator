import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.localeCode = 'system',
    this.biometricLock = false,
    this.autoConfirmTrades = false,
    this.autoConfirmMarket = false,
    this.autoConfirmIntervalMinutes = 15,
    this.autoConfirmDryRun = true,
    this.autoMaxItems = 5,
    this.allowedPartnerSteamIds = const <String>[],
    this.notificationsEnabled = false,
    this.notificationPreviews = false,
    this.inventoryCurrency = 'RUB',
  });

  final ThemeMode themeMode;
  final String localeCode;
  final bool biometricLock;
  final bool autoConfirmTrades;
  final bool autoConfirmMarket;
  final int autoConfirmIntervalMinutes;
  final bool autoConfirmDryRun;
  final int autoMaxItems;
  final List<String> allowedPartnerSteamIds;
  final bool notificationsEnabled;
  final bool notificationPreviews;
  final String inventoryCurrency;

  bool get autoConfirmEnabled => autoConfirmTrades || autoConfirmMarket;
  bool get backgroundChecksEnabled =>
      autoConfirmEnabled || notificationsEnabled;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? localeCode,
    bool? biometricLock,
    bool? autoConfirmTrades,
    bool? autoConfirmMarket,
    int? autoConfirmIntervalMinutes,
    bool? autoConfirmDryRun,
    int? autoMaxItems,
    List<String>? allowedPartnerSteamIds,
    bool? notificationsEnabled,
    bool? notificationPreviews,
    String? inventoryCurrency,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      biometricLock: biometricLock ?? this.biometricLock,
      autoConfirmTrades: autoConfirmTrades ?? this.autoConfirmTrades,
      autoConfirmMarket: autoConfirmMarket ?? this.autoConfirmMarket,
      autoConfirmIntervalMinutes:
          autoConfirmIntervalMinutes ?? this.autoConfirmIntervalMinutes,
      autoConfirmDryRun: autoConfirmDryRun ?? this.autoConfirmDryRun,
      autoMaxItems: autoMaxItems ?? this.autoMaxItems,
      allowedPartnerSteamIds:
          allowedPartnerSteamIds ?? this.allowedPartnerSteamIds,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationPreviews: notificationPreviews ?? this.notificationPreviews,
      inventoryCurrency: inventoryCurrency ?? this.inventoryCurrency,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'themeMode': themeMode.name,
    'localeCode': localeCode,
    'biometricLock': biometricLock,
    'autoConfirmTrades': autoConfirmTrades,
    'autoConfirmMarket': autoConfirmMarket,
    'autoConfirmIntervalMinutes': autoConfirmIntervalMinutes,
    'autoConfirmDryRun': autoConfirmDryRun,
    'autoMaxItems': autoMaxItems,
    'allowedPartnerSteamIds': allowedPartnerSteamIds,
    'notificationsEnabled': notificationsEnabled,
    'notificationPreviews': notificationPreviews,
    'inventoryCurrency': inventoryCurrency,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    int readInt(String key, int fallback) =>
        int.tryParse(json[key]?.toString() ?? '') ?? fallback;
    final partners = json['allowedPartnerSteamIds'];
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == json['themeMode']?.toString(),
        orElse: () => ThemeMode.system,
      ),
      localeCode: json['localeCode']?.toString() ?? 'system',
      biometricLock: json['biometricLock'] == true,
      autoConfirmTrades: json['autoConfirmTrades'] == true,
      autoConfirmMarket: json['autoConfirmMarket'] == true,
      autoConfirmIntervalMinutes: readInt('autoConfirmIntervalMinutes', 15),
      autoConfirmDryRun: json['autoConfirmDryRun'] != false,
      autoMaxItems: readInt('autoMaxItems', 5),
      allowedPartnerSteamIds: partners is List
          ? partners.map((item) => item.toString()).toList(growable: false)
          : const <String>[],
      notificationsEnabled: json['notificationsEnabled'] == true,
      notificationPreviews: json['notificationPreviews'] == true,
      inventoryCurrency: json['inventoryCurrency']?.toString() ?? 'RUB',
    );
  }
}

class SettingsRepository {
  static const _themeKey = 'theme_mode';
  static const _localeKey = 'locale';
  static const _biometricKey = 'biometric_lock';
  static const _autoTradesKey = 'auto_confirm_trades';
  static const _autoMarketKey = 'auto_confirm_market';
  static const _autoIntervalKey = 'auto_confirm_interval';
  static const _autoDryRunKey = 'auto_confirm_dry_run';
  static const _autoMaxItemsKey = 'auto_confirm_max_items';
  static const _allowedPartnersKey = 'auto_confirm_allowed_partners';
  static const _notificationsKey = 'notifications_enabled';
  static const _notificationPreviewsKey = 'notification_previews';
  static const _inventoryCurrencyKey = 'inventory_currency';

  Future<AppSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final themeName = preferences.getString(_themeKey) ?? 'system';
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == themeName,
        orElse: () => ThemeMode.system,
      ),
      localeCode: preferences.getString(_localeKey) ?? 'system',
      biometricLock: preferences.getBool(_biometricKey) ?? false,
      autoConfirmTrades: preferences.getBool(_autoTradesKey) ?? false,
      autoConfirmMarket: preferences.getBool(_autoMarketKey) ?? false,
      autoConfirmIntervalMinutes: preferences.getInt(_autoIntervalKey) ?? 15,
      autoConfirmDryRun: preferences.getBool(_autoDryRunKey) ?? true,
      autoMaxItems: preferences.getInt(_autoMaxItemsKey) ?? 5,
      allowedPartnerSteamIds:
          preferences.getStringList(_allowedPartnersKey) ?? const <String>[],
      notificationsEnabled: preferences.getBool(_notificationsKey) ?? false,
      notificationPreviews:
          preferences.getBool(_notificationPreviewsKey) ?? false,
      inventoryCurrency: preferences.getString(_inventoryCurrencyKey) ?? 'RUB',
    );
  }

  Future<void> save(AppSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait(<Future<bool>>[
      preferences.setString(_themeKey, settings.themeMode.name),
      preferences.setString(_localeKey, settings.localeCode),
      preferences.setBool(_biometricKey, settings.biometricLock),
      preferences.setBool(_autoTradesKey, settings.autoConfirmTrades),
      preferences.setBool(_autoMarketKey, settings.autoConfirmMarket),
      preferences.setInt(_autoIntervalKey, settings.autoConfirmIntervalMinutes),
      preferences.setBool(_autoDryRunKey, settings.autoConfirmDryRun),
      preferences.setInt(_autoMaxItemsKey, settings.autoMaxItems),
      preferences.setStringList(
        _allowedPartnersKey,
        settings.allowedPartnerSteamIds,
      ),
      preferences.setBool(_notificationsKey, settings.notificationsEnabled),
      preferences.setBool(
        _notificationPreviewsKey,
        settings.notificationPreviews,
      ),
      preferences.setString(_inventoryCurrencyKey, settings.inventoryCurrency),
    ]);
  }

  Future<void> restore(AppSettings settings) => save(settings);

  Future<void> saveAutoRun({required int accepted}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'last_auto_run',
      DateTime.now().toUtc().toIso8601String(),
    );
    await preferences.setInt('last_auto_accepted', accepted);
  }

  Future<(DateTime?, int)> loadAutoRun() async {
    final preferences = await SharedPreferences.getInstance();
    final timestamp = DateTime.tryParse(
      preferences.getString('last_auto_run') ?? '',
    );
    return (
      timestamp?.toLocal(),
      preferences.getInt('last_auto_accepted') ?? 0,
    );
  }
}
