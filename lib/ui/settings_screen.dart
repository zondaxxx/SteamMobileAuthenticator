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
        _SectionTitle(strings.text('storage')),
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
