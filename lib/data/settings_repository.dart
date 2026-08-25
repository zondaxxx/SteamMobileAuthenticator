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
  });

  final ThemeMode themeMode;
  final String localeCode;
  final bool biometricLock;
  final bool autoConfirmTrades;
  final bool autoConfirmMarket;
  final int autoConfirmIntervalMinutes;

  bool get autoConfirmEnabled => autoConfirmTrades || autoConfirmMarket;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? localeCode,
    bool? biometricLock,
    bool? autoConfirmTrades,
    bool? autoConfirmMarket,
    int? autoConfirmIntervalMinutes,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      biometricLock: biometricLock ?? this.biometricLock,
      autoConfirmTrades: autoConfirmTrades ?? this.autoConfirmTrades,
      autoConfirmMarket: autoConfirmMarket ?? this.autoConfirmMarket,
      autoConfirmIntervalMinutes:
          autoConfirmIntervalMinutes ?? this.autoConfirmIntervalMinutes,
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
    ]);
  }

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
