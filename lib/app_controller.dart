import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'background_tasks.dart';
import 'core/inventory_client.dart';
import 'core/models.dart';
import 'core/steam_auth_client.dart';
import 'core/steam_client.dart';
import 'core/steam_time.dart';
import 'data/account_vault.dart';
import 'data/backup_service.dart';
import 'data/history_repository.dart';
import 'data/mafile_importer.dart';
import 'data/notification_service.dart';
import 'data/settings_repository.dart';

class AppController extends ChangeNotifier {
  AppController({
    AccountVault? vault,
    SettingsRepository? settingsRepository,
    MaFileImporter? importer,
    SteamClient? steamClient,
    InventoryClient? inventoryClient,
    SteamAuthClient? authClient,
    HistoryRepository? historyRepository,
    BackupService? backupService,
    NotificationService? notificationService,
  }) : _vault = vault ?? AccountVault(),
       _settingsRepository = settingsRepository ?? SettingsRepository(),
       _importer = importer ?? const MaFileImporter(),
       _steamClient = steamClient ?? SteamClient(),
       _inventoryClient = inventoryClient ?? InventoryClient(),
       _authClient = authClient ?? SteamAuthClient(),
       _historyRepository = historyRepository ?? HistoryRepository(),
       _backupService = backupService ?? const BackupService(),
       _notificationService = notificationService ?? NotificationService();

  final AccountVault _vault;
  final SettingsRepository _settingsRepository;
  final MaFileImporter _importer;
  final SteamClient _steamClient;
  final InventoryClient _inventoryClient;
  final SteamAuthClient _authClient;
  final HistoryRepository _historyRepository;
  final BackupService _backupService;
  final NotificationService _notificationService;

  List<SteamAccount> accounts = const <SteamAccount>[];
  List<ActionHistoryEntry> history = const <ActionHistoryEntry>[];
  Map<int, SteamProfile> profiles = const <int, SteamProfile>{};
  Map<int, SessionHealth> sessionHealth = const <int, SessionHealth>{};
  Map<int, String> sessionErrorCodes = const <int, String>{};
  Map<int, InventorySnapshot> inventories = const <int, InventorySnapshot>{};
  AppSettings settings = const AppSettings();
  DateTime? lastAutoRun;
  int lastAutoAccepted = 0;
  int inventoryPricesDone = 0;
  int inventoryPricesTotal = 0;
  bool initialized = false;
  bool busy = false;

  Future<void> initialize() async {
    settings = await _settingsRepository.load();
    accounts = await _vault.loadAll();
    history = await _historyRepository.load();
    sessionHealth = <int, SessionHealth>{
      for (final account in accounts)
        account.steamId: _steamClient.sessionHealth(account),
    };
    final cachedProfiles = <int, SteamProfile>{};
    for (final account in accounts) {
      final profile = account.cachedProfile;
      if (profile != null) cachedProfiles[account.steamId] = profile;
    }
    profiles = cachedProfiles;
    final autoRun = await _settingsRepository.loadAutoRun();
    lastAutoRun = autoRun.$1;
    lastAutoAccepted = autoRun.$2;
    initialized = true;
    notifyListeners();
    try {
      await _notificationService.initialize();
    } catch (_) {
      // Notifications stay optional if platform setup is unavailable.
    }
    await SteamTime.align();
    try {
      await syncAutoConfirmSchedule(settings);
    } catch (_) {
      // Scheduling can be unavailable on simulators; the foreground app works.
    }
    await refreshAccountMetadata();
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
    _refreshSessionHealth();
    notifyListeners();
    await refreshAccountMetadata();
    return imported.length;
  }

  Future<void> deleteAccount(SteamAccount account) async {
    await _vault.delete(account);
    accounts = await _vault.loadAll();
    _refreshSessionHealth();
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
      final known = history
          .map((entry) => entry.confirmationId)
          .whereType<String>()
          .toSet();
      for (final confirmation in batch.items) {
        if (known.contains(confirmation.id)) continue;
        await _historyRepository.add(
          account: batch.account,
          action: HistoryAction.confirmationSeen,
          title: confirmation.headline.isEmpty
              ? confirmation.typeName
              : confirmation.headline,
          details: confirmation.summary.join(' · '),
          confirmationId: confirmation.id,
        );
      }
      history = await _historyRepository.load();
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
      await _historyRepository.add(
        account: updated,
        action: accept ? HistoryAction.accepted : HistoryAction.declined,
        title: confirmation.headline.isEmpty
            ? confirmation.typeName
            : confirmation.headline,
        details: confirmation.summary.join(' · '),
        confirmationId: confirmation.id,
      );
      history = await _historyRepository.load();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<SteamConfirmationDetails> confirmationDetails({
    required SteamAccount account,
    required SteamConfirmation confirmation,
  }) => _steamClient.fetchConfirmationDetails(
    account: account,
    confirmation: confirmation,
  );

  Future<void> refreshAccountMetadata() async {
    sessionHealth = <int, SessionHealth>{
      ...sessionHealth,
      for (final account in accounts)
        if (account.steamId != 0)
          account.steamId: switch (_steamClient.sessionHealth(account)) {
            SessionHealth.healthy ||
            SessionHealth.refreshable => SessionHealth.checking,
            final status => status,
          },
    };
    notifyListeners();
    final nextProfiles = Map<int, SteamProfile>.from(profiles);
    final nextHealth = Map<int, SessionHealth>.from(sessionHealth);
    final nextErrors = Map<int, String>.from(sessionErrorCodes);
    for (final account in List<SteamAccount>.from(accounts)) {
      if (account.steamId == 0) continue;
      final initialHealth = _steamClient.sessionHealth(account);
      nextHealth[account.steamId] = initialHealth;
      nextErrors.remove(account.steamId);
      if (initialHealth == SessionHealth.missing ||
          initialHealth == SessionHealth.expired) {
        // Codes-only or stale sessions still deserve a live nickname and
        // avatar; the public profile endpoint needs no Steam session.
        await _loadPublicProfile(account, nextProfiles);
      }
      if (initialHealth == SessionHealth.missing) continue;
      if (initialHealth == SessionHealth.expired) {
        nextErrors[account.steamId] = 'refresh_expired';
        continue;
      }
      try {
        final result = await _steamClient.fetchProfile(account);
        final cached = result.$1.withCachedProfile(result.$2);
        await _replaceAccount(cached);
        nextProfiles[account.steamId] = result.$2;
        nextHealth[account.steamId] = SessionHealth.healthy;
      } catch (error) {
        await _loadPublicProfile(account, nextProfiles);
        final code = _sessionFailureCode(error);
        nextErrors[account.steamId] = code;
        nextHealth[account.steamId] =
            code == 'refresh_expired' ||
                code == 'session_required' ||
                code == 'session_denied'
            ? SessionHealth.expired
            : SessionHealth.error;
      }
    }
    profiles = nextProfiles;
    sessionHealth = nextHealth;
    sessionErrorCodes = nextErrors;
    notifyListeners();
  }

  Future<void> _loadPublicProfile(
    SteamAccount account,
    Map<int, SteamProfile> target,
  ) async {
    if (account.steamId == 0) return;
    try {
      final profile = await _steamClient.fetchPublicProfile(account.steamId);
      await _replaceAccount(account.withCachedProfile(profile));
      target[account.steamId] = profile;
    } catch (_) {
      // Public profile data is best-effort; codes keep working without it.
    }
  }

  Future<InventorySnapshot> refreshInventory(SteamAccount account) async {
    busy = true;
    inventoryPricesDone = 0;
    inventoryPricesTotal = 0;
    notifyListeners();
    try {
      final snapshot = await _inventoryClient.fetchAll(
        account: account,
        currencyCode: settings.inventoryCurrency,
        onPriceProgress: (done, total) {
          inventoryPricesDone = done;
          inventoryPricesTotal = total;
          notifyListeners();
        },
      );
      inventories = <int, InventorySnapshot>{
        ...inventories,
        account.steamId: snapshot,
      };
      return snapshot;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<Uri?> exportBackup(String password) async {
    busy = true;
    notifyListeners();
    try {
      final bytes = await _backupService.encrypt(
        accounts: accounts,
        settings: settings,
        history: history,
        password: password,
      );
      final date = DateTime.now().toIso8601String().substring(0, 10);
      final result = await FilePicker.saveFile(
        dialogTitle: 'Save encrypted backup',
        fileName: 'SteamMobileAuthenticator-$date.smabackup',
        bytes: bytes,
        mimeType: 'application/octet-stream',
      );
      if (result != null && accounts.isNotEmpty) {
        await _historyRepository.add(
          account: accounts.first,
          action: HistoryAction.backupCreated,
          title: 'Encrypted backup created',
        );
        history = await _historyRepository.load();
      }
      return result;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<PlatformFile?> pickBackup() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['smabackup', 'sma'],
    );
    return files.isEmpty ? null : files.first;
  }

  Future<int> restoreBackup(PlatformFile file, String password) async {
    busy = true;
    notifyListeners();
    try {
      final payload = await _backupService.decrypt(
        await file.readAsBytes(),
        password,
      );
      await _vault.saveAll(payload.accounts);
      await _settingsRepository.restore(payload.settings);
      final existing = await _historyRepository.load();
      final combined =
          <String, ActionHistoryEntry>{
              for (final entry in <ActionHistoryEntry>[
                ...payload.history,
                ...existing,
              ])
                entry.id: entry,
            }.values.toList()
            ..sort((left, right) => right.timestamp.compareTo(left.timestamp));
      await _historyRepository.replaceAll(combined);
      accounts = await _vault.loadAll();
      settings = await _settingsRepository.load();
      history = await _historyRepository.load();
      if (accounts.isNotEmpty) {
        await _historyRepository.add(
          account: accounts.first,
          action: HistoryAction.backupRestored,
          title: 'Encrypted backup restored',
          details: '${payload.accounts.length} account(s)',
        );
        history = await _historyRepository.load();
      }
      _refreshSessionHealth();
      await syncAutoConfirmSchedule(settings);
      return payload.accounts.length;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> requestNotificationPermission() =>
      _notificationService.requestPermission();

  QrChallenge parseQrChallenge(String source) =>
      _authClient.parseQrChallenge(source);

  Future<QrSessionInfo> inspectQr({
    required SteamAccount account,
    required QrChallenge challenge,
  }) async {
    final updated = await _steamClient.ensureAccessToken(account);
    await _replaceAccount(updated);
    return _authClient.getQrSessionInfo(
      challenge: challenge,
      accessToken: updated.session.accessToken!,
    );
  }

  Future<void> approveQr({
    required SteamAccount account,
    required QrChallenge challenge,
  }) async {
    final updated = await _steamClient.ensureAccessToken(account);
    await _replaceAccount(updated);
    await _authClient.approveQr(challenge: challenge, account: updated);
    await _historyRepository.add(
      account: updated,
      action: HistoryAction.qrApproved,
      title: 'QR sign-in approved',
    );
    history = await _historyRepository.load();
    notifyListeners();
  }

  Future<LoginSession> startLogin({
    required String accountName,
    required String password,
  }) async {
    final credentials = await _authClient.encryptCredentials(
      accountName: accountName,
      password: password,
    );
    return _authClient.beginLogin(
      accountName: accountName,
      credentials: credentials,
    );
  }

  Future<void> submitLoginGuard({
    required LoginSession session,
    required String code,
    required int codeType,
  }) => _authClient.submitGuardCode(
    session: session,
    code: code,
    codeType: codeType,
  );

  Future<LoginTokens> pollLogin(LoginSession session) =>
      _authClient.pollLogin(session);

  Future<SteamAccount> beginEnrollment({
    required String accountName,
    required LoginTokens tokens,
  }) async {
    final draft = await _authClient.beginEnrollment(
      accountName: accountName,
      tokens: tokens,
    );
    await _vault.save(draft);
    accounts = await _vault.loadAll();
    _refreshSessionHealth();
    notifyListeners();
    return draft;
  }

  Future<SteamAccount> finalizeEnrollment({
    required SteamAccount draft,
    required String smsCode,
  }) async {
    final enrolled = await _authClient.finalizeEnrollment(
      draft: draft,
      smsCode: smsCode,
    );
    await _replaceAccount(enrolled);
    await _historyRepository.add(
      account: enrolled,
      action: HistoryAction.authenticatorAdded,
      title: 'Mobile authenticator added',
    );
    history = await _historyRepository.load();
    notifyListeners();
    return enrolled;
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

  void _refreshSessionHealth() {
    sessionHealth = <int, SessionHealth>{
      for (final account in accounts)
        account.steamId: _steamClient.sessionHealth(account),
    };
    sessionErrorCodes = const <int, String>{};
  }

  String _sessionFailureCode(Object error) {
    if (error is SteamApiException) return error.code;
    if (error is TimeoutException || error is http.ClientException) {
      return 'network_error';
    }
    return 'profile_failed';
  }

  @override
  void dispose() {
    _steamClient.close();
    _inventoryClient.close();
    _authClient.close();
    super.dispose();
  }
}
