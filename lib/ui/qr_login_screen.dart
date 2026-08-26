import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../app_controller.dart';
import '../core/models.dart';
import '../core/steam_auth_client.dart';
import '../l10n.dart';
import 'neo_design.dart';

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
  bool _torchOn = false;
  Object? _error;
  String? _lastValue;
  DateTime _lastValueAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    try {
      await _scanner.toggleTorch();
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (_) {
      // Torch is optional hardware; scanning keeps working without it.
    }
  }

  Future<void> _scanFromGallery() async {
    if (_processing) return;
    final result = await FilePicker.pickFiles(type: FileType.image);
    final path = result.isEmpty ? null : result.first.path;
    if (path == null) return;
    HapticFeedback.selectionClick();
    try {
      final capture = await _scanner.analyzeImage(
        path,
        formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
      );
      final value = capture?.barcodes
          .map((barcode) => barcode.rawValue)
          .whereType<String>()
          .firstOrNull;
      if (!mounted) return;
      if (value == null) {
        setState(() => _error = const SteamAuthException('qr_invalid'));
        return;
      }
      await _handle(value);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
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
          decoration: const InputDecoration(hintText: 'https://s.team/q/1/…'),
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
    if (value?.trim().isNotEmpty == true && mounted) {
      await _handle(value!.trim());
    }
  }

  Future<void> _handle(String source) async {
    if (_processing) return;
    // The camera fires onDetect continuously for the same frame; ignore
    // repeats of the same payload within a short window.
    final now = DateTime.now();
    if (source == _lastValue &&
        now.difference(_lastValueAt) < const Duration(seconds: 4)) {
      return;
    }
    _lastValue = source;
    _lastValueAt = now;
    HapticFeedback.mediumImpact();
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      await _scanner.stop();
    } catch (_) {
      // Stopping an already-stopped camera must not block the approval flow.
    }
    try {
      final accounts = widget.controller.accounts
          .where((account) => account.steamId != 0)
          .toList(growable: false);
      if (accounts.isEmpty) {
        throw const SteamAuthException('session_required');
      }
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
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            icon: const Icon(Icons.login_rounded),
            title: Text(AppStrings.of(context).text('approve_login')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(info.deviceName),
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
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.verified_user_outlined, size: 18),
                label: Text(AppStrings.of(context).text('approve')),
              ),
            ],
          ),
        ),
      );
      if (approved != true) return;
      await widget.controller.approveQr(account: account, challenge: challenge);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).text('qr_approved'))),
      );
      Navigator.pop(context);
      return;
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) {
        setState(() => _processing = false);
        try {
          await _scanner.start();
        } catch (_) {
          // Restarting may race with disposal; the widget rebuilds anyway.
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final accounts = widget.controller.accounts
        .where((account) => account.steamId != 0)
        .toList(growable: false);
    return NeoScaffold(
      appBar: AppBar(title: Text(strings.text('qr_login'))),
      body: accounts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: NeoSurface(
                  accent: NeoColors.amber,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.key_off_outlined,
                        size: 42,
                        color: NeoColors.amber,
                      ),
                      const SizedBox(height: 14),
                      Text(strings.text('qr_session_required')),
                    ],
                  ),
                ),
              ),
            )
          : SafeArea(
              top: false,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
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
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: _processing
                          ? null
                          : (value) {
                              HapticFeedback.selectionClick();
                              setState(() => _accountIndex = value ?? 0);
                            },
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: NeoSurface(
                        accent: NeoColors.danger,
                        padding: const EdgeInsets.all(13),
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              MobileScanner(
                                controller: _scanner,
                                errorBuilder: (context, error) =>
                                    _CameraError(error: error),
                                onDetect: (capture) {
                                  final value = capture.barcodes
                                      .map((barcode) => barcode.rawValue)
                                      .whereType<String>()
                                      .firstOrNull;
                                  if (value != null) _handle(value);
                                },
                              ),
                              Center(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: _ScanFramePainter(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                    child: const SizedBox.square(
                                      dimension: 240,
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: _processing
                                    ? ColoredBox(
                                        key: const ValueKey<String>('busy'),
                                        color: const Color(0x99060b12),
                                        child: const Center(
                                          child: SizedBox.square(
                                            dimension: 30,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: NeoSurface(
                      radius: 18,
                      padding: const EdgeInsets.fromLTRB(16, 11, 11, 11),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              strings.text('qr_help'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(width: 6),
                          NeoIconButton(
                            tooltip: strings.text('torch'),
                            onPressed: _processing ? null : _toggleTorch,
                            icon: _torchOn
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            accent: _torchOn ? NeoColors.amber : null,
                          ),
                          NeoIconButton(
                            tooltip: strings.text('scan_from_photo'),
                            onPressed: _processing ? null : _scanFromGallery,
                            icon: Icons.photo_outlined,
                          ),
                          NeoIconButton(
                            tooltip: strings.text('paste_link'),
                            onPressed: _processing
                                ? null
                                : () => _manual(accounts),
                            icon: Icons.link_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final permissionDenied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                permissionDenied
                    ? Icons.no_photography_outlined
                    : Icons.camera_alt_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                strings.text(
                  permissionDenied ? 'camera_denied' : 'camera_error',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (permissionDenied) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  strings.text('camera_denied_hint'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  const _ScanFramePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final path = Path();
    const arm = 44.0;
    const radius = 16.0;
    path
      ..moveTo(0, arm)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..lineTo(arm, 0)
      ..moveTo(size.width - arm, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, arm)
      ..moveTo(size.width, size.height - arm)
      ..lineTo(size.width, size.height - radius)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width - radius,
        size.height,
      )
      ..lineTo(size.width - arm, size.height)
      ..moveTo(arm, size.height)
      ..lineTo(radius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - radius)
      ..lineTo(0, size.height - arm);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter oldDelegate) =>
      oldDelegate.color != color;
}
