import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'background_tasks.dart';
import 'core/models.dart';
import 'core/steam_client.dart';
import 'core/steam_time.dart';
import 'data/account_vault.dart';
import 'data/mafile_importer.dart';
import 'data/settings_repository.dart';

class AppController extends ChangeNotifier {
  AppController({
    AccountVault? vault,
    SettingsRepository? settingsRepository,
    MaFileImporter? importer,
    SteamClient? steamClient,
  }) : _vault = vault ?? AccountVault(),
       _settingsRepository = settingsRepository ?? SettingsRepository(),
       _importer = importer ?? const MaFileImporter(),
       _steamClient = steamClient ?? SteamClient();

  final AccountVault _vault;
  final SettingsRepository _settingsRepository;
  final MaFileImporter _importer;
  final SteamClient _steamClient;

  List<SteamAccount> accounts = const <SteamAccount>[];
  AppSettings settings = const AppSettings();
  DateTime? lastAutoRun;
  int lastAutoAccepted = 0;
  bool initialized = false;
  bool busy = false;

  Future<void> initialize() async {
    settings = await _settingsRepository.load();
    accounts = await _vault.loadAll();
    final autoRun = await _settingsRepository.loadAutoRun();
    lastAutoRun = autoRun.$1;
    lastAutoAccepted = autoRun.$2;
    initialized = true;
    notifyListeners();
    await SteamTime.align();
    try {
      await syncAutoConfirmSchedule(settings);
    } catch (_) {
      // Scheduling can be unavailable on simulators; the foreground app works.
    }
  }

  Future<List<PlatformFile>> pickMaFiles() {
    return FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['maFile', 'mafile', 'json'],
    );
  }

  Future<int> importPickedFiles(
    List<PlatformFile> files, {
    String? password,
  }) async {
    final blobs = <MaFileBlob>[];
    for (final file in files) {
      blobs.add(MaFileBlob(name: file.name, bytes: await file.readAsBytes()));
    }
    final imported = await _importer.parse(blobs, password: password);
    await _vault.saveAll(imported);
    accounts = await _vault.loadAll();
    notifyListeners();
    return imported.length;
  }

  Future<void> deleteAccount(SteamAccount account) async {
    await _vault.delete(account);
    accounts = await _vault.loadAll();
    notifyListeners();
  }

  Future<List<SteamConfirmation>> refreshConfirmations(
    SteamAccount account,
  ) async {
    busy = true;
    notifyListeners();
    try {
      final batch = await _steamClient.fetchConfirmations(account);
      await _replaceAccount(batch.account);
      return batch.items;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> actOnConfirmation({
    required SteamAccount account,
    required SteamConfirmation confirmation,
    required bool accept,
  }) async {
    busy = true;
    notifyListeners();
    try {
      final updated = await _steamClient.actOnConfirmation(
        account: account,
        confirmation: confirmation,
        accept: accept,
      );
      await _replaceAccount(updated);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> updateSettings(AppSettings next) async {
    settings = next;
    notifyListeners();
    await _settingsRepository.save(next);
    try {
      await syncAutoConfirmSchedule(next);
    } catch (_) {
      // The setting remains valid; foreground checks are still available.
    }
  }

  Future<void> refreshAutoRunStatus() async {
    final autoRun = await _settingsRepository.loadAutoRun();
    lastAutoRun = autoRun.$1;
    lastAutoAccepted = autoRun.$2;
    notifyListeners();
  }

  Future<void> _replaceAccount(SteamAccount updated) async {
    await _vault.save(updated);
    final id = _vault.idFor(updated);
    accounts = <SteamAccount>[
      for (final account in accounts)
        if (_vault.idFor(account) == id) updated else account,
    ];
    notifyListeners();
  }

  @override
  void dispose() {
    _steamClient.close();
    super.dispose();
  }
}
