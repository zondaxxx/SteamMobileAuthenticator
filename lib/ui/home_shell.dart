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
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'STEAM NEO',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.2,
                                ),
                          ),
                          const SizedBox(height: 3),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.2),
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
                        ],
                      ),
                    ),
                    NeoIconButton(
                      tooltip: strings.text('qr_login'),
                      onPressed: widget.controller.accounts.isEmpty
                          ? null
                          : _openQr,
                      icon: Icons.qr_code_scanner_rounded,
                      accent: NeoColors.cyan,
                    ),
                    const SizedBox(width: 9),
                    NeoIconButton(
                      tooltip: strings.text('add_authenticator'),
                      onPressed: _openEnrollment,
                      icon: Icons.person_add_alt_1_rounded,
                      accent: NeoColors.violet,
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
        floatingActionButton: AnimatedScale(
          scale: _index == 0 ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: NeoPressable(
            onTap: _import,
            haptic: true,
            semanticLabel: strings.text('import'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[NeoColors.blue, Color(0xff317ed9)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: NeoColors.blue.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.file_open_rounded, color: Colors.white),
                  const SizedBox(width: 9),
                  Text(
                    strings.text('import'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 5, 12, 9),
      child: Container(
        height: 70,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: (dark ? const Color(0xff03080c) : Colors.white).withValues(
            alpha: 0.96,
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.34 : 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
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
    return NeoPressable(
      onTap: onTap,
      semanticLabel: destination.label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        height: 56,
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    primary.withValues(alpha: 0.23),
                    NeoColors.cyan.withValues(alpha: 0.08),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(18),
          border: selected
              ? Border.all(color: primary.withValues(alpha: 0.22))
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: const Duration(milliseconds: 240),
              child: Icon(
                destination.icon,
                size: 22,
                color: selected
                    ? primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected
                    ? primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
