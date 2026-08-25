import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'core/models.dart';
import 'core/steam_client.dart';
import 'data/account_vault.dart';
import 'data/history_repository.dart';
import 'data/notification_service.dart';
import 'data/settings_repository.dart';

const autoConfirmTaskId = 'com.zondaxxx.steammobileauthenticator.autoconfirm';
const autoConfirmTaskName = 'autoConfirmSteamTransactions';

@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    if (taskName != autoConfirmTaskId &&
        taskName != autoConfirmTaskName &&
        taskName != Workmanager.iOSBackgroundTask) {
      return true;
    }
    return AutoConfirmRunner().run();
  });
}

Future<void> syncAutoConfirmSchedule(AppSettings settings) async {
  if (!settings.backgroundChecksEnabled) {
    await Workmanager().cancelByUniqueName(autoConfirmTaskId);
    return;
  }
  await Workmanager().registerPeriodicTask(
    autoConfirmTaskId,
    autoConfirmTaskName,
    frequency: Duration(minutes: settings.autoConfirmIntervalMinutes),
    initialDelay: const Duration(minutes: 1),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
  );
}

class AutoConfirmRunner {
  AutoConfirmRunner({
    AccountVault? vault,
    SettingsRepository? settingsRepository,
    SteamClient? client,
    HistoryRepository? historyRepository,
    NotificationService? notificationService,
  }) : _vault = vault ?? AccountVault(),
       _settingsRepository = settingsRepository ?? SettingsRepository(),
       _client = client ?? SteamClient(),
       _historyRepository = historyRepository ?? HistoryRepository(),
       _notificationService = notificationService ?? NotificationService();

  final AccountVault _vault;
  final SettingsRepository _settingsRepository;
  final SteamClient _client;
  final HistoryRepository _historyRepository;
  final NotificationService _notificationService;

  Future<bool> run() async {
    var accepted = 0;
    try {
      final settings = await _settingsRepository.load();
      if (!settings.backgroundChecksEnabled) return true;
      final accounts = await _vault.loadAll();
      final knownConfirmationIds = (await _historyRepository.load())
          .map((entry) => entry.confirmationId)
          .whereType<String>()
          .toSet();
      for (final account in accounts) {
        try {
          final batch = await _client.fetchConfirmations(account);
          var working = batch.account;
          await _vault.save(working);
          final incoming = batch.items
              .where((item) => !knownConfirmationIds.contains(item.id))
              .toList(growable: false);
          for (final confirmation in incoming) {
            await _historyRepository.add(
              account: working,
              action: HistoryAction.confirmationSeen,
              title: confirmation.headline.isEmpty
                  ? confirmation.typeName
                  : confirmation.headline,
              details: confirmation.summary.join(' · '),
              confirmationId: confirmation.id,
            );
          }
          if (settings.notificationsEnabled && incoming.isNotEmpty) {
            try {
              await _notificationService.showIncoming(
                account: working,
                confirmations: incoming,
                showPreview: settings.notificationPreviews,
              );
            } catch (_) {
              // A denied notification must not block rule evaluation.
            }
          }
          for (final confirmation in batch.items) {
            if (!(confirmation.isTrade && settings.autoConfirmTrades) &&
                !(confirmation.isMarket && settings.autoConfirmMarket)) {
              continue;
            }
            String? skipReason;
            if (settings.autoConfirmDryRun) {
              skipReason = 'Dry run: no action was sent';
            } else if (confirmation.isTrade) {
              try {
                final details = await _client.fetchConfirmationDetails(
                  account: working,
                  confirmation: confirmation,
                );
                if (!details.hasVerifiedPartner) {
                  skipReason = 'Partner could not be verified';
                } else if (!settings.allowedPartnerSteamIds.contains(
                  details.partnerSteamId,
                )) {
                  skipReason = 'Partner is not on the allowlist';
                } else if (details.itemCount <= 0) {
                  skipReason = 'Trade items could not be verified';
                } else if (details.itemCount > settings.autoMaxItems) {
                  skipReason =
                      'Trade has ${details.itemCount} items; limit is ${settings.autoMaxItems}';
                }
              } catch (_) {
                skipReason = 'Trade details could not be loaded';
              }
            }
            if (skipReason != null) {
              await _historyRepository.add(
                account: working,
                action: HistoryAction.autoSkipped,
                title: confirmation.headline.isEmpty
                    ? confirmation.typeName
                    : confirmation.headline,
                details: skipReason,
                confirmationId: confirmation.id,
              );
              continue;
            }
            working = await _client.actOnConfirmation(
              account: working,
              confirmation: confirmation,
              accept: true,
            );
            accepted++;
            await _historyRepository.add(
              account: working,
              action: HistoryAction.autoAccepted,
              title: confirmation.headline.isEmpty
                  ? confirmation.typeName
                  : confirmation.headline,
              details: confirmation.summary.join(' · '),
              confirmationId: confirmation.id,
            );
          }
          await _vault.save(working);
        } catch (_) {
          // One stale account must not prevent other accounts from being checked.
        }
      }
      await _settingsRepository.saveAutoRun(accepted: accepted);
      return true;
    } catch (_) {
      return false;
    } finally {
      _client.close();
    }
  }
}
