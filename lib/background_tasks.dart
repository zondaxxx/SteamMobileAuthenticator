import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'core/steam_client.dart';
import 'data/account_vault.dart';
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
  if (!settings.autoConfirmEnabled) {
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
  }) : _vault = vault ?? AccountVault(),
       _settingsRepository = settingsRepository ?? SettingsRepository(),
       _client = client ?? SteamClient();

  final AccountVault _vault;
  final SettingsRepository _settingsRepository;
  final SteamClient _client;

  Future<bool> run() async {
    var accepted = 0;
    try {
      final settings = await _settingsRepository.load();
      if (!settings.autoConfirmEnabled) return true;
      final accounts = await _vault.loadAll();
      for (final account in accounts) {
        try {
          final batch = await _client.fetchConfirmations(account);
          var working = batch.account;
          await _vault.save(working);
          for (final confirmation in batch.items) {
            final shouldAccept =
                (confirmation.isTrade && settings.autoConfirmTrades) ||
                (confirmation.isMarket && settings.autoConfirmMarket);
            if (!shouldAccept) continue;
            working = await _client.actOnConfirmation(
              account: working,
              confirmation: confirmation,
              accept: true,
            );
            accepted++;
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
