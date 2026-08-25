import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../core/models.dart';
import '../l10n.dart';

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
    final index = _selectedIndex.clamp(0, accounts.length - 1);
    return accounts[index];
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
                          accounts[index].accountName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedIndex = value;
                      _items = const <SteamConfirmation>[];
                      _error = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: _loading ? null : _refresh,
                tooltip: strings.text('refresh'),
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
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
          child: _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      strings.text('no_confirmations'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _ConfirmationCard(
                        item: item,
                        disabled: _loading,
                        onDetails: () => _showDetails(item),
                        onAccept: () => _act(item, true),
                        onDecline: () => _act(item, false),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _refresh() async {
    final account = _selectedAccount;
    if (account == null) return;
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
    final future = widget.controller.confirmationDetails(
      account: account,
      confirmation: confirmation,
    );
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
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
                      Text(
                        '${AppStrings.of(context).text('items')}: '
                        '${details.itemCount}',
                      ),
                    const SizedBox(height: 12),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: iconUri?.scheme == 'https'
                      ? Image.network(
                          item.icon,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.swap_horiz_rounded),
                        )
                      : const Icon(Icons.swap_horiz_rounded),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.headline.isEmpty ? item.typeName : item.headline,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (item.typeName.isNotEmpty)
                        Text(
                          item.typeName,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.summary.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              for (final line in item.summary)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(line),
                ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: disabled ? null : onDetails,
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(strings.text('details')),
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: disabled ? null : onDecline,
                    child: Text(strings.text('decline')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: disabled ? null : onAccept,
                    child: Text(strings.text('accept')),
                  ),
                ),
              ],
            ),
          ],
        ),
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
    final scheme = Theme.of(context).colorScheme;
    final color = isError ? scheme.error : scheme.tertiary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
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
