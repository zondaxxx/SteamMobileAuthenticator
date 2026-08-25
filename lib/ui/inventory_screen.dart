import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../app_controller.dart';
import '../core/models.dart';
import '../l10n.dart';
import 'neo_design.dart';

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
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedIndex = value;
                      _error = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              NeoIconButton(
                tooltip: strings.text('refresh'),
                onPressed: widget.controller.busy ? null : _refresh,
                icon: widget.controller.busy
                    ? Icons.hourglass_top_rounded
                    : Icons.refresh_rounded,
                accent: NeoColors.violet,
              ),
            ],
          ),
        ),
        if (widget.controller.busy &&
            widget.controller.inventoryPricesTotal > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: NeoSurface(
              accent: NeoColors.violet,
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.auto_graph_rounded,
                        size: 18,
                        color: NeoColors.violet,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${strings.text('pricing_items')} '
                          '${widget.controller.inventoryPricesDone}/'
                          '${widget.controller.inventoryPricesTotal}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value:
                          widget.controller.inventoryPricesDone /
                          widget.controller.inventoryPricesTotal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: NeoSurface(
              accent: NeoColors.danger,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.error_outline_rounded,
                    color: NeoColors.danger,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(strings.error(_error!))),
                ],
              ),
            ),
          ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: snapshot == null
                ? _EmptyInventory(
                    key: const ValueKey<String>('empty-inventory'),
                    onRefresh: _refresh,
                  )
                : _InventoryList(
                    key: ValueKey<DateTime>(snapshot.updatedAt),
                    snapshot: snapshot,
                    onRefresh: _refresh,
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _refresh() async {
    final account = _account;
    if (account == null) return;
    HapticFeedback.selectionClick();
    setState(() => _error = null);
    try {
      await widget.controller.refreshInventory(account);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory({super.key, required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
        child: NeoSurface(
          accent: NeoColors.violet,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[NeoColors.violet, NeoColors.blue],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: NeoColors.violet.withValues(alpha: 0.28),
                      blurRadius: 28,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                strings.text('inventory_empty'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.calculate_outlined),
                label: Text(strings.text('calculate_inventory')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryList extends StatelessWidget {
  const _InventoryList({
    super.key,
    required this.snapshot,
    required this.onRefresh,
  });

  final InventorySnapshot snapshot;
  final Future<void> Function() onRefresh;

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
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        itemCount: items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _InventorySummary(
              snapshot: snapshot,
              formatter: formatter,
              strings: strings,
            );
          }
          final item = items[index - 1];
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 220 + index.clamp(0, 8) * 30),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(12 * (1 - value), 0),
                child: child,
              ),
            ),
            child: NeoSurface(
              radius: 20,
              accent: item.price == null ? NeoColors.amber : NeoColors.mint,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: item.iconUrl.isEmpty
                        ? const Icon(Icons.category_outlined)
                        : Image.network(
                            item.iconUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.broken_image_outlined),
                          ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'App ${item.appId}'
                          '${item.amount > 1 ? ' · ×${item.amount}' : ''}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item.totalPrice == null
                        ? '—'
                        : formatter.format(item.totalPrice),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: item.totalPrice == null
                          ? NeoColors.amber
                          : NeoColors.mint,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InventorySummary extends StatelessWidget {
  const _InventorySummary({
    required this.snapshot,
    required this.formatter,
    required this.strings,
  });

  final InventorySnapshot snapshot;
  final NumberFormat formatter;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final coverage = snapshot.totalAssets == 0
        ? 0.0
        : snapshot.valuedAssets / snapshot.totalAssets;
    return NeoSurface(
      accent: NeoColors.violet,
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const NeoPill(
                label: 'MARKET ESTIMATE',
                icon: Icons.auto_graph_rounded,
                color: NeoColors.violet,
              ),
              const Spacer(),
              NeoPill(label: snapshot.currencyCode, color: NeoColors.cyan),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            formatter.format(snapshot.totalValue),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: NeoColors.mint,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '${strings.text('inventory_assets')}: ${snapshot.totalAssets} · '
            '${strings.text('valued_assets')}: ${snapshot.valuedAssets}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: coverage.clamp(0, 1)),
          ),
          if (snapshot.partial) ...<Widget>[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: NeoColors.amber,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.text('inventory_partial'),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: NeoColors.amber),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
