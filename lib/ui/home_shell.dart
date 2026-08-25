import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../data/mafile_importer.dart';
import '../l10n.dart';
import 'accounts_screen.dart';
import 'confirmations_screen.dart';
import 'enrollment_screen.dart';
import 'history_screen.dart';
import 'inventory_screen.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: <Widget>[
          IconButton(
            tooltip: strings.text('qr_login'),
            onPressed: widget.controller.accounts.isEmpty ? null : _openQr,
            icon: const Icon(Icons.qr_code_scanner_rounded),
          ),
          IconButton(
            tooltip: strings.text('add_authenticator'),
            onPressed: _openEnrollment,
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: <Widget>[
          AccountsScreen(controller: widget.controller, onImport: _import),
          ConfirmationsScreen(controller: widget.controller),
          InventoryScreen(controller: widget.controller),
          HistoryScreen(controller: widget.controller),
          SettingsScreen(controller: widget.controller),
        ],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: _import,
              icon: const Icon(Icons.file_open_rounded),
              label: Text(strings.text('import')),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.password_rounded),
            selectedIcon: const Icon(Icons.password_rounded),
            label: strings.text('accounts'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.task_alt_rounded),
            selectedIcon: const Icon(Icons.task_alt_rounded),
            label: strings.text('confirmations'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.inventory_2_outlined),
            selectedIcon: const Icon(Icons.inventory_2_rounded),
            label: strings.text('inventory'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_rounded),
            selectedIcon: const Icon(Icons.history_rounded),
            label: strings.text('history'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_rounded),
            selectedIcon: const Icon(Icons.tune_rounded),
            label: strings.text('settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _openQr() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => QrLoginScreen(controller: widget.controller),
      ),
    );
  }

  Future<void> _openEnrollment() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
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
