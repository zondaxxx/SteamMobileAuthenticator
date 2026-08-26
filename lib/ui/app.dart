import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:local_auth/local_auth.dart';

import '../app_controller.dart';
import '../l10n.dart';
import 'home_shell.dart';
import 'neo_design.dart';

class SteamAuthenticatorApp extends StatelessWidget {
  const SteamAuthenticatorApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final localeCode = controller.settings.localeCode;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Steam Mobile Authenticator',
          themeMode: controller.settings.themeMode,
          theme: steamNeoTheme(Brightness.light),
          darkTheme: steamNeoTheme(Brightness.dark),
          locale: localeCode == 'system' ? null : Locale(localeCode),
          supportedLocales: const <Locale>[Locale('en'), Locale('ru')],
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: controller.initialized
              ? DeviceLockGate(
                  key: ValueKey(controller.settings.biometricLock),
                  enabled: controller.settings.biometricLock,
                  child: HomeShell(controller: controller),
                )
              : const _LoadingScreen(),
        );
      },
    );
  }
}

class _LoadingScreen extends StatefulWidget {
  const _LoadingScreen();

  @override
  State<_LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<_LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NeoBackground(
      child: Scaffold(
        body: Center(
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) => Transform.scale(
              scale: 0.94 + _pulse.value * 0.08,
              child: Opacity(opacity: 0.7 + _pulse.value * 0.3, child: child),
            ),
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: NeoColors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: NeoColors.blue.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: NeoColors.blue,
                size: 36,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DeviceLockGate extends StatefulWidget {
  const DeviceLockGate({super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<DeviceLockGate> createState() => _DeviceLockGateState();
}

class _DeviceLockGateState extends State<DeviceLockGate>
    with WidgetsBindingObserver {
  final _auth = LocalAuthentication();
  bool _unlocked = false;
  bool _authenticating = false;
  bool _unavailable = false;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _unlocked = !widget.enabled;
    if (widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.enabled) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed &&
        _backgroundedAt != null &&
        DateTime.now().difference(_backgroundedAt!) >
            const Duration(seconds: 20)) {
      _backgroundedAt = null;
      if (mounted) setState(() => _unlocked = false);
      _unlock();
    }
  }

  Future<void> _unlock() async {
    if (_authenticating || !mounted) return;
    final reason = AppStrings.of(context).text('biometric_reason');
    setState(() {
      _authenticating = true;
      _unavailable = false;
    });
    try {
      if (!await _auth.isDeviceSupported()) {
        if (mounted) setState(() => _unavailable = true);
        return;
      }
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
      if (mounted) setState(() => _unlocked = authenticated);
    } catch (_) {
      if (mounted) setState(() => _unavailable = true);
    } finally {
      if (mounted) setState(() => _authenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;
    final strings = AppStrings.of(context);
    return NeoBackground(
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: NeoSurface(
                padding: const EdgeInsets.all(28),
                accent: NeoColors.cyan,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: NeoColors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: NeoColors.blue.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 34,
                        color: NeoColors.blue,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      strings.text('app_name'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (_unavailable) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        strings.text('auth_unavailable'),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _authenticating ? null : _unlock,
                        icon: _authenticating
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.fingerprint_rounded),
                        label: Text(strings.text('unlock')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
