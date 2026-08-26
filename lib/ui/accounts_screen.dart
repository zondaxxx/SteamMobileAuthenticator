import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../core/models.dart';
import '../core/steam_guard.dart';
import '../core/steam_time.dart';
import '../l10n.dart';
import 'neo_design.dart';

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
  late final PageController _pages;

  @override
  void initState() {
    super.initState();
    _pages = PageController(viewportFraction: 0.94);
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = widget.controller.accounts;
    if (accounts.isEmpty) {
      return _EmptyAccounts(onImport: widget.onImport);
    }
    return PageView.builder(
      controller: _pages,
      itemCount: accounts.length,
      onPageChanged: (_) => HapticFeedback.selectionClick(),
      itemBuilder: (context, index) {
        final account = accounts[index];
        return AnimatedBuilder(
          animation: _pages,
          builder: (context, child) {
            var scale = 1.0;
            if (_pages.hasClients && _pages.position.hasContentDimensions) {
              final page = _pages.page ?? _pages.initialPage.toDouble();
              scale = (1 - ((page - index).abs() * 0.04)).clamp(0.95, 1);
            }
            return Transform.scale(scale: scale, child: child);
          },
          child: _AccountCard(
            account: account,
            profile: widget.controller.profiles[account.steamId],
            health:
                widget.controller.sessionHealth[account.steamId] ??
                SessionHealth.missing,
            onSessionTap: () => _showSessionInfo(account),
            onDelete: () => _delete(account),
          ),
        );
      },
    );
  }

  Future<void> _showSessionInfo(SteamAccount account) async {
    final strings = AppStrings.of(context);
    final health =
        widget.controller.sessionHealth[account.steamId] ??
        SessionHealth.missing;
    final errorCode = widget.controller.sessionErrorCodes[account.steamId];
    final color = _healthColor(health);
    final canRetry =
        health == SessionHealth.error || health == SessionHealth.refreshable;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.text('session_status_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(_healthIcon(health), size: 20, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      strings.text('session_health_${health.name}'),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              if (errorCode != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  strings.errorCode(errorCode),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 14),
              Text(
                strings.text('session_health_${health.name}_body'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Text(
                strings.text('session_codes_unaffected'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (health == SessionHealth.expired ||
                  health == SessionHealth.missing ||
                  health == SessionHealth.checking) ...<Widget>[
                const SizedBox(height: 14),
                Text(
                  strings.text('session_reimport_advice'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        actions: <Widget>[
          if (canRetry)
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await widget.controller.refreshAccountMetadata();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(strings.text('refresh')),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.text('done')),
          ),
        ],
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

  Color _healthColor(SessionHealth value) => switch (value) {
    SessionHealth.healthy => NeoColors.mint,
    SessionHealth.refreshable || SessionHealth.checking => NeoColors.amber,
    SessionHealth.expired ||
    SessionHealth.missing ||
    SessionHealth.error => NeoColors.danger,
  };

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
    required this.onSessionTap,
    required this.onDelete,
  });

  final SteamAccount account;
  final SteamProfile? profile;
  final SessionHealth health;
  final VoidCallback onSessionTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final code = SteamGuard.code(account, SteamTime.now());
    final remaining = SteamTime.secondsRemainingPrecise();
    final name = profile?.personaName ?? account.accountName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 16),
      child: NeoSurface(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(20, 20, 12, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                NeoAvatar(
                  name: name,
                  url: profile?.avatarUrl,
                  size: 52,
                  radius: 15,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      NeoPressable(
                        onTap: onSessionTap,
                        semanticLabel:
                            '${strings.text('session_health_${health.name}')}. '
                            '${strings.text('details')}',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            NeoDot(color: _healthColor(health), size: 7),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                strings.text('session_health_${health.name}'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
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
                          const Icon(Icons.delete_outline_rounded, size: 20),
                          const SizedBox(width: 12),
                          Text(strings.text('delete')),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: NeoPressable(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    HapticFeedback.mediumImpact();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(strings.text('copied'))),
                    );
                  },
                  semanticLabel: strings.text('tap_to_copy'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 380),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                              child: FittedBox(
                                key: ValueKey<String>(code),
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  code,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 8,
                                        fontFeatures: const <FontFeature>[
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            remaining.ceil().toString(),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: remaining <= 5
                                      ? NeoColors.danger
                                      : scheme.onSurfaceVariant,
                                  fontFeatures: const <FontFeature>[
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: (remaining / 30).clamp(0, 1),
                          minHeight: 3,
                          backgroundColor: scheme.outlineVariant,
                          color: remaining <= 5
                              ? NeoColors.danger
                              : scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              account.steamId == 0
                  ? account.accountName
                  : account.steamId.toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _healthColor(SessionHealth value) => switch (value) {
    SessionHealth.healthy => NeoColors.mint,
    SessionHealth.refreshable || SessionHealth.checking => NeoColors.amber,
    SessionHealth.expired ||
    SessionHealth.missing ||
    SessionHealth.error => NeoColors.danger,
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
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.shield_outlined,
              size: 44,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 18),
            Text(
              strings.text('no_accounts'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              strings.text('no_accounts_body'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.file_open_outlined, size: 18),
              label: Text(strings.text('import')),
            ),
          ],
        ),
      ),
    );
  }
}
