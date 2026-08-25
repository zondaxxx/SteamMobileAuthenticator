import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../core/models.dart';
import '../l10n.dart';
import 'neo_design.dart';

class ConfirmationsScreen extends StatefulWidget {
  const ConfirmationsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ConfirmationsScreen> createState() => _ConfirmationsScreenState();
}

class _ConfirmationsScreenState extends State<ConfirmationsScreen> {
  int _selectedIndex = 0;
  List<SteamConfirmation> _items = const <SteamConfirmation>[];
  bool _loading = false;
  Object? _error;

  SteamAccount? get _selectedAccount {
    final accounts = widget.controller.accounts;
    if (accounts.isEmpty) return null;
    return accounts[_selectedIndex.clamp(0, accounts.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final accounts = widget.controller.accounts;
    if (accounts.isEmpty) {
      return Center(child: Text(strings.text('no_accounts_body')));
    }
    final selected = _selectedAccount!;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedIndex.clamp(0, accounts.length - 1),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    labelText: strings.text('select_account'),
                  ),
                  items: <DropdownMenuItem<int>>[
                    for (var index = 0; index < accounts.length; index++)
                      DropdownMenuItem<int>(
                        value: index,
                        child: Text(
                          widget
                                  .controller
                                  .profiles[accounts[index].steamId]
                                  ?.personaName ??
                              accounts[index].accountName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedIndex = value;
                      _items = const <SteamConfirmation>[];
                      _error = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              NeoIconButton(
                onPressed: _loading ? null : _refresh,
                tooltip: strings.text('refresh'),
                icon: _loading
                    ? Icons.hourglass_top_rounded
                    : Icons.refresh_rounded,
                accent: NeoColors.cyan,
              ),
            ],
          ),
        ),
        if (!selected.canConfirm)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _InfoBanner(
              icon: Icons.key_off_outlined,
              message: strings.text('session_missing'),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _InfoBanner(
              icon: Icons.error_outline_rounded,
              message: strings.error(_error!),
              isError: true,
            ),
          ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            child: _items.isEmpty
                ? Center(
                    key: const ValueKey<String>('empty-confirmations'),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: NeoSurface(
                        accent: NeoColors.mint,
                        padding: const EdgeInsets.all(26),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.done_all_rounded,
                              size: 46,
                              color: NeoColors.mint,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              strings.text('no_confirmations'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    key: const ValueKey<String>('confirmation-list'),
                    onRefresh: _refresh,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: Duration(milliseconds: 280 + index * 35),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 18 * (1 - value)),
                              child: child,
                            ),
                          ),
                          child: _ConfirmationCard(
                            item: item,
                            disabled: _loading,
                            onDetails: () => _showDetails(item),
                            onAccept: () => _act(item, true),
                            onDecline: () => _act(item, false),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _refresh() async {
    final account = _selectedAccount;
    if (account == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.controller.refreshConfirmations(account);
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _act(SteamConfirmation confirmation, bool accept) async {
    final account = _selectedAccount;
    if (account == null) return;
    if (accept) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.controller.actOnConfirmation(
        account: account,
        confirmation: confirmation,
        accept: accept,
      );
      if (mounted) {
        setState(() {
          _items = _items
              .where((item) => item.id != confirmation.id)
              .toList(growable: false);
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showDetails(SteamConfirmation confirmation) async {
    final account = _selectedAccount;
    if (account == null) return;
    HapticFeedback.selectionClick();
    final future = widget.controller.confirmationDetails(
      account: account,
      confirmation: confirmation,
    );
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          confirmation.isTrade
              ? Icons.swap_horiz_rounded
              : Icons.storefront_outlined,
        ),
        title: Text(
          confirmation.headline.isEmpty
              ? confirmation.typeName
              : confirmation.headline,
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<SteamConfirmationDetails>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text(AppStrings.of(context).error(snapshot.error!));
              }
              final details = snapshot.data!;
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (details.partnerName?.isNotEmpty == true)
                      Text(
                        details.partnerName!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    if (details.partnerSteamId?.isNotEmpty == true)
                      Text('SteamID: ${details.partnerSteamId}'),
                    if (details.itemCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: NeoPill(
                          label:
                              '${AppStrings.of(context).text('items')}: ${details.itemCount}',
                          icon: Icons.inventory_2_outlined,
                        ),
                      ),
                    const SizedBox(height: 14),
                    SelectableText(details.plainText),
                  ],
                ),
              );
            },
          ),
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.of(context).text('done')),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationCard extends StatelessWidget {
  const _ConfirmationCard({
    required this.item,
    required this.disabled,
    required this.onDetails,
    required this.onAccept,
    required this.onDecline,
  });

  final SteamConfirmation item;
  final bool disabled;
  final VoidCallback onDetails;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final iconUri = Uri.tryParse(item.icon);
    final accent = item.isTrade ? NeoColors.cyan : NeoColors.violet;
    return NeoSurface(
      accent: accent,
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      accent.withValues(alpha: 0.24),
                      accent.withValues(alpha: 0.07),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: accent.withValues(alpha: 0.25)),
                ),
                clipBehavior: Clip.antiAlias,
                child: iconUri?.scheme == 'https'
                    ? Image.network(
                        item.icon,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.swap_horiz_rounded),
                      )
                    : Icon(
                        item.isTrade
                            ? Icons.swap_horiz_rounded
                            : Icons.storefront_outlined,
                        color: accent,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.headline.isEmpty ? item.typeName : item.headline,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (item.typeName.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      NeoPill(label: item.typeName, color: accent),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (item.summary.isNotEmpty) ...<Widget>[
            const SizedBox(height: 15),
            for (final line in item.summary)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
          ],
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              IconButton(
                tooltip: strings.text('details'),
                onPressed: disabled ? null : onDetails,
                icon: const Icon(Icons.receipt_long_outlined),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: disabled ? null : onDecline,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text(strings.text('decline')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: disabled ? null : onAccept,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(strings.text('accept')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.message,
    this.isError = false,
  });

  final IconData icon;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? NeoColors.danger : NeoColors.amber;
    return NeoSurface(
      accent: color,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
