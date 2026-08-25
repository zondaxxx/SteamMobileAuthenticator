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
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pages = PageController(viewportFraction: 0.9);
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
    final strings = AppStrings.of(context);
    if (accounts.isEmpty) {
      return _EmptyAccounts(onImport: widget.onImport);
    }
    final visiblePage = _page.clamp(0, accounts.length - 1);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
          child: Row(
            children: <Widget>[
              NeoPill(
                icon: Icons.shield_outlined,
                label: '${accounts.length} ${strings.text('accounts')}',
                color: NeoColors.mint,
              ),
              const Spacer(),
              if (accounts.length > 1)
                NeoPill(
                  icon: Icons.swipe_rounded,
                  label: '${visiblePage + 1}/${accounts.length}',
                ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pages,
            itemCount: accounts.length,
            onPageChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _page = value);
            },
            itemBuilder: (context, index) {
              final account = accounts[index];
              return AnimatedBuilder(
                animation: _pages,
                builder: (context, child) {
                  var scale = 1.0;
                  if (_pages.hasClients &&
                      _pages.position.hasContentDimensions) {
                    final page = _pages.page ?? _pages.initialPage.toDouble();
                    scale = (1 - ((page - index).abs() * 0.045)).clamp(0.94, 1);
                  }
                  return Transform.scale(scale: scale, child: child);
                },
                child: _AccountCard(
                  account: account,
                  profile: widget.controller.profiles[account.steamId],
                  health:
                      widget.controller.sessionHealth[account.steamId] ??
                      SessionHealth.missing,
                  accent: _accentFor(index),
                  onDelete: () => _delete(account),
                ),
              );
            },
          ),
        ),
        if (accounts.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 82),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (var index = 0; index < accounts.length; index++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: index == visiblePage ? 22 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: index == visiblePage
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ),
          )
        else
          const SizedBox(height: 82),
      ],
    );
  }

  Color _accentFor(int index) => const <Color>[
    NeoColors.blue,
    NeoColors.violet,
    NeoColors.cyan,
    NeoColors.mint,
  ][index % 4];

  Future<void> _delete(SteamAccount account) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded),
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
    required this.accent,
    required this.onDelete,
  });

  final SteamAccount account;
  final SteamProfile? profile;
  final SessionHealth health;
  final Color accent;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final code = SteamGuard.code(account, SteamTime.now());
    final remaining = SteamTime.secondsRemainingPrecise();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 18),
      child: NeoSurface(
        accent: accent,
        radius: 32,
        padding: const EdgeInsets.fromLTRB(22, 22, 14, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Hero(
                  tag: 'steam-avatar-${account.steamId}-${account.accountName}',
                  child: Container(
                    width: 58,
                    height: 58,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[accent, NeoColors.cyan],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: accent.withValues(alpha: 0.25),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: ColoredBox(
                        color: scheme.surface,
                        child: profile?.avatarUrl?.isNotEmpty == true
                            ? Image.network(
                                profile!.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _initial(),
                              )
                            : _initial(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        profile?.personaName ?? account.accountName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      NeoPill(
                        icon: _healthIcon(health),
                        label: strings.text('session_health_${health.name}'),
                        color: _healthColor(health),
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
            const Spacer(),
            Text(
              account.steamId == 0
                  ? account.accountName
                  : account.steamId.toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 10),
            NeoPressable(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: code));
                HapticFeedback.mediumImpact();
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(strings.text('copied'))));
              },
              semanticLabel: strings.text('tap_to_copy'),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 450),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      ),
                      child: FittedBox(
                        key: ValueKey<String>(code),
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          code,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 8,
                                fontFeatures: const <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox.square(
                    dimension: 58,
                    child: CustomPaint(
                      painter: _TimerRingPainter(
                        value: (remaining / 30).clamp(0, 1),
                        accent: remaining <= 5 ? NeoColors.danger : accent,
                        track: scheme.outlineVariant,
                      ),
                      child: Center(
                        child: Text(
                          remaining.ceil().toString(),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: remaining <= 5
                                    ? NeoColors.danger
                                    : accent,
                                fontFeatures: const <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Icon(Icons.touch_app_rounded, size: 16, color: accent),
                const SizedBox(width: 7),
                Text(
                  strings.text('tap_to_copy'),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _initial() => Center(
    child: Text(
      (profile?.personaName ?? account.accountName).characters.first
          .toUpperCase(),
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
    ),
  );

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
}

class _TimerRingPainter extends CustomPainter {
  const _TimerRingPainter({
    required this.value,
    required this.accent,
    required this.track,
  });

  final double value;
  final Color accent;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 4;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      6.28318 * value,
      false,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TimerRingPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.accent != accent ||
      oldDelegate.track != track;
}

class _EmptyAccounts extends StatelessWidget {
  const _EmptyAccounts({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 92),
        child: NeoSurface(
          accent: NeoColors.cyan,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[NeoColors.blue, NeoColors.cyan],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: NeoColors.blue.withValues(alpha: 0.28),
                      blurRadius: 28,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 38,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                strings.text('no_accounts'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 9),
              Text(
                strings.text('no_accounts_body'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onImport,
                  icon: const Icon(Icons.file_open_rounded),
                  label: Text(strings.text('import')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
