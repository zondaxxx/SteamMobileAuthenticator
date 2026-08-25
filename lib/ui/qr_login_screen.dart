import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../app_controller.dart';
import '../core/models.dart';
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
    return NeoScaffold(
      appBar: AppBar(
        title: Text(strings.text('qr_login')),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: NeoPill(
              label: 'SECURE SCAN',
              icon: Icons.shield_outlined,
              color: NeoColors.mint,
            ),
          ),
        ],
      ),
      body: accounts.isEmpty
          ? Center(child: Text(strings.text('qr_session_required')))
          : SafeArea(
              top: false,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                          : (value) {
                              HapticFeedback.selectionClick();
                              setState(() => _accountIndex = value ?? 0);
                            },
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(
                              color: NeoColors.cyan.withValues(alpha: 0.28),
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
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
                              const ColoredBox(color: Color(0x1900060c)),
                              Center(
                                child: IgnorePointer(
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.96, end: 1),
                                    duration: const Duration(milliseconds: 900),
                                    curve: Curves.easeOutBack,
                                    builder: (context, value, child) =>
                                        Transform.scale(
                                          scale:
                                              MediaQuery.of(context)
                                                  .disableAnimations
                                              ? 1
                                              : value,
                                          child: child,
                                        ),
                                    child: const _ScanFrame(),
                                  ),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: _processing
                                    ? ColoredBox(
                                        key: const ValueKey<String>(
                                          'processing',
                                        ),
                                        color: const Color(0x9900060c),
                                        child: Center(
                                          child: NeoSurface(
                                            accent: NeoColors.cyan,
                                            padding: const EdgeInsets.all(20),
                                            child: const SizedBox.square(
                                              dimension: 34,
                                              child:
                                                  CircularProgressIndicator(),
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
                      accent: NeoColors.cyan,
                      radius: 20,
                      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: NeoColors.cyan,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              strings.text('qr_help'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(width: 8),
                          NeoIconButton(
                            tooltip: strings.text('paste_link'),
                            onPressed: _processing
                                ? null
                                : () => _manual(accounts),
                            icon: Icons.link_rounded,
                            accent: NeoColors.violet,
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
    HapticFeedback.mediumImpact();
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

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 248,
    child: CustomPaint(painter: _ScanFramePainter()),
  );
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..color = NeoColors.cyan.withValues(alpha: 0.23)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final line = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[NeoColors.cyan, NeoColors.blue],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final path = Path();
    const arm = 48.0;
    const radius = 18.0;
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
    canvas
      ..drawPath(path, glow)
      ..drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
