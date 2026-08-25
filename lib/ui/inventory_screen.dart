import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_controller.dart';
import '../core/models.dart';
import '../l10n.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  int _selectedIndex = 0;
  Object? _error;

  SteamAccount? get _account {
    if (widget.controller.accounts.isEmpty) return null;
    return widget.controller.accounts[_selectedIndex.clamp(
      0,
      widget.controller.accounts.length - 1,
    )];
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final accounts = widget.controller.accounts;
    if (accounts.isEmpty) {
      return Center(child: Text(strings.text('no_accounts_body')));
    }
    final account = _account!;
    final snapshot = widget.controller.inventories[account.steamId];
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
                    setState(() {
                      _selectedIndex = value;
                      _error = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: strings.text('refresh'),
                onPressed: widget.controller.busy ? null : _refresh,
                icon: widget.controller.busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
        if (widget.controller.busy &&
            widget.controller.inventoryPricesTotal > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                LinearProgressIndicator(
                  value:
                      widget.controller.inventoryPricesDone /
                      widget.controller.inventoryPricesTotal,
                ),
                const SizedBox(height: 6),
                Text(
                  '${strings.text('pricing_items')} '
                  '${widget.controller.inventoryPricesDone}/'
                  '${widget.controller.inventoryPricesTotal}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: const Icon(Icons.error_outline_rounded),
                title: Text(strings.error(_error!)),
              ),
            ),
          ),
        Expanded(
          child: snapshot == null
              ? _EmptyInventory(onRefresh: _refresh)
              : _InventoryList(snapshot: snapshot),
        ),
      ],
    );
  }

  Future<void> _refresh() async {
    final account = _account;
    if (account == null) return;
    setState(() => _error = null);
    try {
      await widget.controller.refreshInventory(account);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.inventory_2_outlined, size: 56),
            const SizedBox(height: 16),
            Text(strings.text('inventory_empty'), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.calculate_outlined),
              label: Text(strings.text('calculate_inventory')),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryList extends StatelessWidget {
  const _InventoryList({required this.snapshot});

  final InventorySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final formatter = NumberFormat.simpleCurrency(
      name: snapshot.currencyCode,
      decimalDigits: 2,
    );
    final items = List<InventoryItem>.from(snapshot.items)
      ..sort(
        (left, right) =>
            (right.totalPrice ?? -1).compareTo(left.totalPrice ?? -1),
      );
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        itemCount: items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      formatter.format(snapshot.totalValue),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${strings.text('inventory_assets')}: ${snapshot.totalAssets} · '
                      '${strings.text('valued_assets')}: ${snapshot.valuedAssets}',
                    ),
                    if (snapshot.partial) ...<Widget>[
                      const SizedBox(height: 10),
                      Text(
                        strings.text('inventory_partial'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
          final item = items[index - 1];
          return Card(
            child: ListTile(
              leading: item.iconUrl.isEmpty
                  ? const SizedBox.square(
                      dimension: 48,
                      child: Icon(Icons.category_outlined),
                    )
                  : Image.network(
                      item.iconUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.broken_image_outlined),
                    ),
              title: Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'App ${item.appId}${item.amount > 1 ? ' · ×${item.amount}' : ''}',
              ),
              trailing: Text(
                item.totalPrice == null
                    ? '—'
                    : formatter.format(item.totalPrice),
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          );
        },
      ),
    );
  }
}
