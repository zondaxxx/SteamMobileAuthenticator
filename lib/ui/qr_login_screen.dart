import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../app_controller.dart';
import '../core/models.dart';
import '../l10n.dart';

class QrLoginScreen extends StatefulWidget {
  const QrLoginScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<QrLoginScreen> createState() => _QrLoginScreenState();
}

class _QrLoginScreenState extends State<QrLoginScreen> {
  final _scanner = MobileScannerController(
    formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
  );
  int _accountIndex = 0;
  bool _processing = false;
  Object? _error;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final accounts = widget.controller.accounts
        .where((account) => account.steamId != 0)
        .toList(growable: false);
    return Scaffold(
      appBar: AppBar(title: Text(strings.text('qr_login'))),
      body: accounts.isEmpty
          ? Center(child: Text(strings.text('qr_session_required')))
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<int>(
                    initialValue: _accountIndex.clamp(0, accounts.length - 1),
                    decoration: InputDecoration(
                      labelText: strings.text('approve_as'),
                      prefixIcon: const Icon(Icons.person_outline_rounded),
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
                          ),
                        ),
                    ],
                    onChanged: _processing
                        ? null
                        : (value) => setState(() => _accountIndex = value ?? 0),
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      MobileScanner(
                        controller: _scanner,
                        onDetect: (capture) {
                          final value = capture.barcodes
                              .map((barcode) => barcode.rawValue)
                              .whereType<String>()
                              .firstOrNull;
                          if (value != null) _handle(value, accounts);
                        },
                      ),
                      Center(
                        child: IgnorePointer(
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 3),
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                        ),
                      ),
                      if (_processing)
                        const ColoredBox(
                          color: Color(0x66000000),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: <Widget>[
                        Expanded(child: Text(strings.text('qr_help'))),
                        IconButton.filledTonal(
                          tooltip: strings.text('paste_link'),
                          onPressed: _processing
                              ? null
                              : () => _manual(accounts),
                          icon: const Icon(Icons.link_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _manual(List<SteamAccount> accounts) async {
    final input = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.of(context).text('paste_link')),
        content: TextField(
          controller: input,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'https://s.team/q/…'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.of(context).text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, input.text),
            child: Text(AppStrings.of(context).text('continue')),
          ),
        ],
      ),
    );
    input.dispose();
    if (value?.isNotEmpty == true && mounted) await _handle(value!, accounts);
  }

  Future<void> _handle(String source, List<SteamAccount> accounts) async {
    if (_processing) return;
    setState(() {
      _processing = true;
      _error = null;
    });
    await _scanner.stop();
    try {
      final challenge = widget.controller.parseQrChallenge(source);
      final account = accounts[_accountIndex.clamp(0, accounts.length - 1)];
      final info = await widget.controller.inspectQr(
        account: account,
        challenge: challenge,
      );
      if (!mounted) return;
      final approved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.login_rounded),
          title: Text(AppStrings.of(context).text('approve_login')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                info.deviceName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (info.ip.isNotEmpty) Text('IP: ${info.ip}'),
              if (info.location.isNotEmpty) Text(info.location),
              const SizedBox(height: 12),
              Text(AppStrings.of(context).text('qr_verify_warning')),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppStrings.of(context).text('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppStrings.of(context).text('approve')),
            ),
          ],
        ),
      );
      if (approved == true) {
        await widget.controller.approveQr(
          account: account,
          challenge: challenge,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).text('qr_approved'))),
        );
        Navigator.pop(context);
        return;
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) {
        setState(() => _processing = false);
        await _scanner.start();
      }
    }
  }
}
