import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';

import '../app_controller.dart';
import '../l10n.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final settings = controller.settings;
    final lastRun = controller.lastAutoRun;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: <Widget>[
        _SectionTitle(strings.text('theme')),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SegmentedButton<ThemeMode>(
              segments: <ButtonSegment<ThemeMode>>[
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto_rounded),
                  label: Text(strings.text('theme_system')),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode_outlined),
                  label: Text(strings.text('theme_light')),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode_outlined),
                  label: Text(strings.text('theme_dark')),
                ),
              ],
              selected: <ThemeMode>{settings.themeMode},
              onSelectionChanged: (selection) {
                controller.updateSettings(
                  settings.copyWith(themeMode: selection.first),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.language_rounded),
            title: Text(strings.text('language')),
            trailing: DropdownButton<String>(
              value: settings.localeCode,
              underline: const SizedBox.shrink(),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem(
                  value: 'system',
                  child: Text(strings.text('language_system')),
                ),
                DropdownMenuItem(
                  value: 'ru',
                  child: Text(strings.text('language_ru')),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(strings.text('language_en')),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                controller.updateSettings(settings.copyWith(localeCode: value));
              },
            ),
          ),
        ),
        _SectionTitle(strings.text('security')),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.fingerprint_rounded),
            title: Text(strings.text('biometric_lock')),
            subtitle: Text(strings.text('biometric_lock_body')),
            value: settings.biometricLock,
            onChanged: (value) => _setDeviceLock(context, value),
          ),
        ),
        _SectionTitle(strings.text('automation')),
        Card(
          child: Column(
            children: <Widget>[
              SwitchListTile(
                secondary: const Icon(Icons.swap_horiz_rounded),
                title: Text(strings.text('auto_trades')),
                value: settings.autoConfirmTrades,
                onChanged: (value) =>
                    _setAutomation(context, value: value, isTrade: true),
              ),
              const Divider(height: 1, indent: 56),
              SwitchListTile(
                secondary: const Icon(Icons.storefront_outlined),
                title: Text(strings.text('auto_market')),
                value: settings.autoConfirmMarket,
                onChanged: (value) =>
                    _setAutomation(context, value: value, isTrade: false),
              ),
              const Divider(height: 1, indent: 56),
              SwitchListTile(
                secondary: const Icon(Icons.science_outlined),
                title: Text(strings.text('dry_run')),
                subtitle: Text(strings.text('dry_run_body')),
                value: settings.autoConfirmDryRun,
                onChanged: (value) => _setDryRun(context, value),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.people_outline_rounded),
                title: Text(strings.text('partner_allowlist')),
                subtitle: Text(
                  settings.allowedPartnerSteamIds.isEmpty
                      ? strings.text('allowlist_empty')
                      : settings.allowedPartnerSteamIds.join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _editAllowlist(context),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.production_quantity_limits_rounded),
                title: Text(strings.text('max_trade_items')),
                trailing: DropdownButton<int>(
                  value: settings.autoMaxItems,
                  underline: const SizedBox.shrink(),
                  items: const <int>[1, 3, 5, 10, 25]
                      .map(
                        (value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    controller.updateSettings(
                      settings.copyWith(autoMaxItems: value),
                    );
                  },
                ),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.schedule_rounded),
                title: Text(strings.text('interval')),
                trailing: DropdownButton<int>(
                  value: settings.autoConfirmIntervalMinutes,
                  underline: const SizedBox.shrink(),
                  items: <DropdownMenuItem<int>>[
                    DropdownMenuItem(
                      value: 15,
                      child: Text(strings.text('minutes_15')),
                    ),
                    DropdownMenuItem(
                      value: 30,
                      child: Text(strings.text('minutes_30')),
                    ),
                    DropdownMenuItem(
                      value: 60,
                      child: Text(strings.text('minutes_60')),
                    ),
                  ],
                  onChanged: settings.autoConfirmEnabled
                      ? (value) {
                          if (value == null) return;
                          controller.updateSettings(
                            settings.copyWith(
                              autoConfirmIntervalMinutes: value,
                            ),
                          );
                        }
                      : null,
                ),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: Text(strings.text('last_run')),
                subtitle: Text(
                  lastRun == null
                      ? strings.text('never')
                      : '${DateFormat.yMd(locale).add_Hm().format(lastRun)} · '
                            '${controller.lastAutoAccepted} ${strings.text('accepted_count')}',
                ),
                trailing: IconButton(
                  onPressed: controller.refreshAutoRunStatus,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _NoteCard(
          icon: Icons.info_outline_rounded,
          text: strings.text('background_note'),
        ),
        _SectionTitle(strings.text('notifications')),
        Card(
          child: Column(
            children: <Widget>[
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: Text(strings.text('incoming_notifications')),
                subtitle: Text(strings.text('incoming_notifications_body')),
                value: settings.notificationsEnabled,
                onChanged: (value) => _setNotifications(context, value),
              ),
              const Divider(height: 1, indent: 56),
              SwitchListTile(
                secondary: const Icon(Icons.visibility_outlined),
                title: Text(strings.text('notification_previews')),
                subtitle: Text(strings.text('notification_previews_body')),
                value: settings.notificationPreviews,
                onChanged: settings.notificationsEnabled
                    ? (value) => controller.updateSettings(
                        settings.copyWith(notificationPreviews: value),
                      )
                    : null,
              ),
            ],
          ),
        ),
        _SectionTitle(strings.text('inventory_settings')),
        Card(
          child: ListTile(
            leading: const Icon(Icons.currency_exchange_rounded),
            title: Text(strings.text('currency')),
            trailing: DropdownButton<String>(
              value: settings.inventoryCurrency,
              underline: const SizedBox.shrink(),
              items: const <String>['RUB', 'USD', 'EUR', 'GBP', 'UAH']
                  .map(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                controller.updateSettings(
                  settings.copyWith(inventoryCurrency: value),
                );
              },
            ),
          ),
        ),
        _SectionTitle(strings.text('storage')),
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: Text(strings.text('export_backup')),
                subtitle: Text(strings.text('backup_encrypted_body')),
                onTap: controller.busy ? null : () => _exportBackup(context),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.restore_rounded),
                title: Text(strings.text('restore_backup')),
                subtitle: Text(strings.text('restore_backup_body')),
                onTap: controller.busy ? null : () => _restoreBackup(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _NoteCard(
          icon: Icons.shield_outlined,
          text: strings.text('storage_body'),
        ),
        const SizedBox(height: 12),
        _NoteCard(
          icon: Icons.warning_amber_rounded,
          text: strings.text('disclaimer'),
        ),
      ],
    );
  }

  Future<void> _editAllowlist(BuildContext context) async {
    final strings = AppStrings.of(context);
    final input = TextEditingController(
      text: controller.settings.allowedPartnerSteamIds.join('\n'),
    );
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.text('partner_allowlist')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(strings.text('allowlist_help')),
            const SizedBox(height: 12),
            TextField(
              controller: input,
              autofocus: true,
              minLines: 3,
              maxLines: 8,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '76561198…\n76561199…',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.text('cancel')),
          ),
          FilledButton(
            onPressed: () {
              final ids = RegExp(r'7656119\d{10}')
                  .allMatches(input.text)
                  .map((match) => match.group(0)!)
                  .toSet()
                  .toList();
              Navigator.pop(context, ids);
            },
            child: Text(strings.text('save')),
          ),
        ],
      ),
    );
    input.dispose();
    if (result == null) return;
    await controller.updateSettings(
      controller.settings.copyWith(allowedPartnerSteamIds: result),
    );
  }

  Future<void> _setNotifications(BuildContext context, bool value) async {
    if (value) {
      final granted = await controller.requestNotificationPermission();
      if (!granted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context).text('notification_denied')),
          ),
        );
        return;
      }
    }
    await controller.updateSettings(
      controller.settings.copyWith(notificationsEnabled: value),
    );
  }

  Future<void> _setDryRun(BuildContext context, bool value) async {
    if (!value) {
      final strings = AppStrings.of(context);
      final approved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded),
          title: Text(strings.text('disable_dry_run_title')),
          content: Text(strings.text('disable_dry_run_body')),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(strings.text('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(strings.text('enable_live_actions')),
            ),
          ],
        ),
      );
      if (approved != true) return;
    }
    await controller.updateSettings(
      controller.settings.copyWith(autoConfirmDryRun: value),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    final password = await _askBackupPassword(context, confirm: true);
    if (password == null || !context.mounted) return;
    try {
      final saved = await controller.exportBackup(password);
      if (!context.mounted || saved == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).text('backup_saved'))),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).error(error))),
      );
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final file = await controller.pickBackup();
    if (file == null || !context.mounted) return;
    final password = await _askBackupPassword(context);
    if (password == null || !context.mounted) return;
    try {
      final count = await controller.restoreBackup(file, password);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.of(context).text('backup_restored')} $count',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).error(error))),
      );
    }
  }

  Future<String?> _askBackupPassword(
    BuildContext context, {
    bool confirm = false,
  }) async {
    final strings = AppStrings.of(context);
    final first = TextEditingController();
    final second = TextEditingController();
    String? validation;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(strings.text('backup_password')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: first,
                autofocus: true,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: strings.text('password'),
                  errorText: validation,
                ),
              ),
              if (confirm) ...<Widget>[
                const SizedBox(height: 12),
                TextField(
                  controller: second,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: strings.text('repeat_password'),
                  ),
                ),
              ],
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings.text('cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (first.text.length < 8) {
                  setState(() => validation = strings.text('password_8'));
                  return;
                }
                if (confirm && first.text != second.text) {
                  setState(
                    () => validation = strings.text('password_mismatch'),
                  );
                  return;
                }
                Navigator.pop(context, first.text);
              },
              child: Text(strings.text('continue')),
            ),
          ],
        ),
      ),
    );
    first.dispose();
    second.dispose();
    return result;
  }

  Future<void> _setDeviceLock(BuildContext context, bool value) async {
    final strings = AppStrings.of(context);
    if (value) {
      try {
        if (!await LocalAuthentication().isDeviceSupported()) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.text('auth_unavailable'))),
          );
          return;
        }
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.text('auth_unavailable'))),
        );
        return;
      }
    }
    await controller.updateSettings(
      controller.settings.copyWith(biometricLock: value),
    );
  }

  Future<void> _setAutomation(
    BuildContext context, {
    required bool value,
    required bool isTrade,
  }) async {
    if (value) {
      final strings = AppStrings.of(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded),
          title: Text(strings.text('auto_warning_title')),
          content: Text(strings.text('auto_warning_body')),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(strings.text('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(strings.text('enable')),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    final settings = controller.settings;
    await controller.updateSettings(
      isTrade
          ? settings.copyWith(autoConfirmTrades: value)
          : settings.copyWith(autoConfirmMarket: value),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
