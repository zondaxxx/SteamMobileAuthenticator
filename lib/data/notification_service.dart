import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/models.dart';

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('notification_icon');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return false;
  }

  Future<void> showIncoming({
    required SteamAccount account,
    required List<SteamConfirmation> confirmations,
    required bool showPreview,
  }) async {
    if (confirmations.isEmpty) return;
    await initialize();
    final tradeCount = confirmations.where((item) => item.isTrade).length;
    final marketCount = confirmations.where((item) => item.isMarket).length;
    final body = showPreview
        ? <String>[
            if (tradeCount > 0) 'Trades: $tradeCount',
            if (marketCount > 0) 'Market: $marketCount',
            if (tradeCount + marketCount < confirmations.length)
              'Other: ${confirmations.length - tradeCount - marketCount}',
          ].join(' · ')
        : 'Open the app to review safely.';
    await _plugin.show(
      id: account.steamId.hashCode & 0x7fffffff,
      title: '${account.accountName}: ${confirmations.length} pending',
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'incoming_confirmations',
          'Steam confirmations',
          channelDescription: 'Incoming Steam trades and market confirmations',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.status,
        ),
        iOS: DarwinNotificationDetails(threadIdentifier: 'steam-confirmations'),
      ),
      payload: 'confirmations',
    );
  }
}
