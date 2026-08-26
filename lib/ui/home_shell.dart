import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../data/mafile_importer.dart';
import '../l10n.dart';
import 'accounts_screen.dart';
import 'confirmations_screen.dart';
import 'enrollment_screen.dart';
import 'history_screen.dart';
import 'inventory_screen.dart';
import 'neo_design.dart';
import 'qr_login_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final PageController _pages;

  @override
  void initState() {
    super.initState();
    _pages = PageController();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final titles = <String>[
      strings.text('accounts'),
      strings.text('confirmations'),
      strings.text('inventory'),
      strings.text('history'),
      strings.text('settings'),
    ];
    final destinations = <_NeoDestination>[
      _NeoDestination(Icons.password_rounded, strings.text('accounts')),
      _NeoDestination(Icons.task_alt_rounded, strings.text('confirmations')),
      _NeoDestination(Icons.inventory_2_rounded, strings.text('inventory')),
      _NeoDestination(Icons.history_rounded, strings.text('history')),
      _NeoDestination(Icons.tune_rounded, strings.text('settings')),
    ];
    return NeoBackground(
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.15),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: Text(
                          titles[_index],
                          key: ValueKey<int>(_index),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    NeoIconButton(
                      tooltip: strings.text('import'),
                      onPressed: _import,
                      icon: Icons.file_open_outlined,
                    ),
                    const SizedBox(width: 8),
                    NeoIconButton(
                      tooltip: strings.text('qr_login'),
                      onPressed: widget.controller.accounts.isEmpty
                          ? null
                          : _openQr,
                      icon: Icons.qr_code_scanner_rounded,
                    ),
                    const SizedBox(width: 8),
                    NeoIconButton(
                      tooltip: strings.text('add_authenticator'),
                      onPressed: _openEnrollment,
                      icon: Icons.person_add_alt_1_rounded,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  physics: const NeverScrollableScrollPhysics(),
                  children: <Widget>[
                    AccountsScreen(
                      controller: widget.controller,
                      onImport: _import,
                    ),
                    ConfirmationsScreen(controller: widget.controller),
                    InventoryScreen(controller: widget.controller),
                    HistoryScreen(controller: widget.controller),
                    SettingsScreen(controller: widget.controller),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _NeoNavigation(
          selectedIndex: _index,
          destinations: destinations,
          onSelected: _selectPage,
        ),
      ),
    );
  }

  void _selectPage(int value) {
    if (value == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = value);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _pages.jumpToPage(value);
    } else {
      _pages.animateToPage(
        value,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _openQr() {
    return Navigator.of(context).push<void>(
      NeoRoute<void>(
        builder: (_) => QrLoginScreen(controller: widget.controller),
      ),
    );
  }

  Future<void> _openEnrollment() {
    return Navigator.of(context).push<void>(
      NeoRoute<void>(
        builder: (_) => EnrollmentScreen(controller: widget.controller),
      ),
    );
  }

  Future<void> _import() async {
    final strings = AppStrings.of(context);
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.text('import')),
        content: Text(strings.text('import_help')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.text('continue')),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;
    final result = await widget.controller.pickMaFiles();
    if (result.isEmpty || !mounted) return;
    await _tryImport(result);
  }

  Future<void> _tryImport(List<PlatformFile> result, {String? password}) async {
    final strings = AppStrings.of(context);
    try {
      final count = await widget.controller.importPickedFiles(
        result,
        password: password,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${strings.text('imported')}$count')),
      );
    } on MaFileImportException catch (error) {
      if (!mounted) return;
      if (error.code == 'password_required') {
        final entered = await _askPassword();
        if (entered != null && mounted) {
          await _tryImport(result, password: entered);
        }
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.error(error))));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.error(error))));
    }
  }

  Future<String?> _askPassword() async {
    final strings = AppStrings.of(context);
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.text('password')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: controller,
              autofocus: true,
              obscureText: true,
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
            const SizedBox(height: 12),
            Text(strings.text('password_hint')),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(strings.text('continue')),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}

class _NeoDestination {
  const _NeoDestination(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _NeoNavigation extends StatelessWidget {
  const _NeoNavigation({
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<_NeoDestination> destinations;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: <Widget>[
              for (var index = 0; index < destinations.length; index++)
                Expanded(
                  child: _NeoNavigationItem(
                    destination: destinations[index],
                    selected: index == selectedIndex,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeoNavigationItem extends StatelessWidget {
  const _NeoNavigationItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _NeoDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final tint = selected
        ? primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return NeoPressable(
      onTap: onTap,
      haptic: true,
      semanticLabel: destination.label,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(destination.icon, size: 22, color: tint),
          const SizedBox(height: 4),
          Text(
            destination.label,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tint,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
