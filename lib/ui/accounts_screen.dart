import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../core/models.dart';
import '../core/steam_guard.dart';
import '../core/steam_time.dart';
import '../l10n.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({
    super.key,
    required this.controller,
    required this.onImport,
  });

  final AppController controller;
  final VoidCallback onImport;

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = widget.controller.accounts;
    if (accounts.isEmpty) {
      return _EmptyAccounts(onImport: widget.onImport);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
      itemCount: accounts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _AccountCard(
        account: accounts[index],
        profile: widget.controller.profiles[accounts[index].steamId],
        health:
            widget.controller.sessionHealth[accounts[index].steamId] ??
            SessionHealth.missing,
        onDelete: () => _delete(accounts[index]),
      ),
    );
  }

  Future<void> _delete(SteamAccount account) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.text('delete_title')),
        content: Text(strings.text('delete_body')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.text('cancel')),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.text('delete')),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.controller.deleteAccount(account);
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.profile,
    required this.health,
    required this.onDelete,
  });

  final SteamAccount account;
  final SteamProfile? profile;
  final SessionHealth health;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final code = SteamGuard.code(account, SteamTime.now());
    final remaining = SteamTime.secondsRemaining();
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: code));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(strings.text('copied'))));
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 23,
                    foregroundImage: profile?.avatarUrl?.isNotEmpty == true
                        ? NetworkImage(profile!.avatarUrl!)
                        : null,
                    child: profile?.avatarUrl?.isNotEmpty == true
                        ? null
                        : Text(
                            (profile?.personaName ?? account.accountName)
                                .characters
                                .first
                                .toUpperCase(),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          profile?.personaName ?? account.accountName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (account.steamId != 0)
                          Row(
                            children: <Widget>[
                              Icon(
                                _healthIcon(health),
                                size: 14,
                                color: _healthColor(context, health),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${strings.text('session_health_${health.name}')} · '
                                  '${account.steamId}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.delete_outline_rounded),
                            const SizedBox(width: 12),
                            Text(strings.text('delete')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      code,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 7,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 5),
                    child: Text(
                      '${remaining}s',
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: scheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: remaining / 30,
                  minHeight: 5,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _healthIcon(SessionHealth value) => switch (value) {
    SessionHealth.healthy => Icons.cloud_done_outlined,
    SessionHealth.refreshable => Icons.sync_rounded,
    SessionHealth.expired => Icons.cloud_off_outlined,
    SessionHealth.missing => Icons.key_off_outlined,
    SessionHealth.checking => Icons.hourglass_top_rounded,
    SessionHealth.error => Icons.error_outline_rounded,
  };

  Color _healthColor(BuildContext context, SessionHealth value) =>
      switch (value) {
        SessionHealth.healthy => Colors.green,
        SessionHealth.refreshable || SessionHealth.checking => Colors.orange,
        SessionHealth.expired ||
        SessionHealth.missing ||
        SessionHealth.error => Theme.of(context).colorScheme.error,
      };
}

class _EmptyAccounts extends StatelessWidget {
  const _EmptyAccounts({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.shield_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              strings.text('no_accounts'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(strings.text('no_accounts_body'), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.file_open_rounded),
              label: Text(strings.text('import')),
            ),
          ],
        ),
      ),
    );
  }
}
