import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../core/models.dart';
import '../l10n.dart';
import 'neo_design.dart';

enum _EnrollStep { credentials, guard, polling, recovery, sms, done }

class EnrollmentScreen extends StatefulWidget {
  const EnrollmentScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  final _accountName = TextEditingController();
  final _password = TextEditingController();
  final _guardCode = TextEditingController();
  final _smsCode = TextEditingController();
  _EnrollStep _step = _EnrollStep.credentials;
  LoginSession? _loginSession;
  SteamAccount? _draft;
  int _guardType = 2;
  bool _busy = false;
  bool _recoverySaved = false;
  Object? _error;

  @override
  void dispose() {
    _accountName.dispose();
    _password.dispose();
    _guardCode.dispose();
    _smsCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return NeoScaffold(
      appBar: AppBar(title: Text(strings.text('add_authenticator'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            _Progress(step: _step.index),
            const SizedBox(height: 24),
            if (_error != null)
              NeoSurface(
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
            if (_error != null) const SizedBox(height: 12),
            NeoSurface(
              accent: _stepAccent,
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0.06),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey<_EnrollStep>(_step),
                  child: switch (_step) {
                    _EnrollStep.credentials => _credentials(strings),
                    _EnrollStep.guard => _guard(strings),
                    _EnrollStep.polling => _waiting(strings),
                    _EnrollStep.recovery => _recovery(strings),
                    _EnrollStep.sms => _sms(strings),
                    _EnrollStep.done => _done(strings),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _stepAccent => switch (_step) {
    _EnrollStep.credentials => NeoColors.blue,
    _EnrollStep.guard || _EnrollStep.polling => NeoColors.cyan,
    _EnrollStep.recovery => NeoColors.amber,
    _EnrollStep.sms => NeoColors.violet,
    _EnrollStep.done => NeoColors.mint,
  };

  Widget _credentials(AppStrings strings) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Text(strings.text('enroll_intro')),
      const SizedBox(height: 18),
      TextField(
        controller: _accountName,
        enabled: !_busy,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: strings.text('steam_login'),
          prefixIcon: const Icon(Icons.person_outline_rounded),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _password,
        enabled: !_busy,
        obscureText: true,
        onSubmitted: (_) => _start(),
        decoration: InputDecoration(
          labelText: strings.text('steam_password'),
          prefixIcon: const Icon(Icons.lock_outline_rounded),
        ),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: _busy ? null : _start,
        icon: _busy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.login_rounded),
        label: Text(strings.text('sign_in')),
      ),
      const SizedBox(height: 14),
      Text(
        strings.text('credentials_private'),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );

  Widget _guard(AppStrings strings) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Text(
        _guardType == 4
            ? strings.text('approve_in_steam')
            : _guardType == 3
            ? strings.text('enter_guard_code')
            : strings.text('enter_email_code'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 16),
      if (_guardType != 4)
        TextField(
          controller: _guardCode,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          onSubmitted: (_) => _submitGuard(),
          decoration: InputDecoration(
            labelText: strings.text('guard_code'),
            prefixIcon: const Icon(Icons.password_rounded),
          ),
        ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: _busy
            ? null
            : _guardType == 4
            ? _poll
            : _submitGuard,
        child: Text(strings.text('continue')),
      ),
    ],
  );

  Widget _waiting(AppStrings strings) => Column(
    children: <Widget>[
      const SizedBox(height: 40),
      const CircularProgressIndicator(),
      const SizedBox(height: 20),
      Text(strings.text('waiting_steam')),
    ],
  );

  Widget _recovery(AppStrings strings) {
    final code = _draft?.raw['revocation_code']?.toString() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Icon(
          Icons.key_rounded,
          size: 52,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          strings.text('save_recovery_title'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(strings.text('save_recovery_body'), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        NeoSurface(
          accent: NeoColors.amber,
          radius: 20,
          padding: EdgeInsets.zero,
          child: ListTile(
            title: SelectableText(
              code,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 3),
            ),
            trailing: IconButton(
              onPressed: () => Clipboard.setData(ClipboardData(text: code)),
              icon: const Icon(Icons.copy_rounded),
            ),
          ),
        ),
        CheckboxListTile(
          value: _recoverySaved,
          onChanged: (value) => setState(() => _recoverySaved = value ?? false),
          title: Text(strings.text('recovery_saved_check')),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _recoverySaved
              ? () => setState(() => _step = _EnrollStep.sms)
              : null,
          child: Text(strings.text('continue')),
        ),
      ],
    );
  }

  Widget _sms(AppStrings strings) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Text(
        strings.text('enter_sms'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _smsCode,
        autofocus: true,
        keyboardType: TextInputType.number,
        onSubmitted: (_) => _finalize(),
        decoration: InputDecoration(
          labelText: strings.text('sms_code'),
          prefixIcon: const Icon(Icons.sms_outlined),
        ),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: _busy ? null : _finalize,
        icon: _busy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_moderator_rounded),
        label: Text(strings.text('activate')),
      ),
    ],
  );

  Widget _done(AppStrings strings) => Column(
    children: <Widget>[
      const SizedBox(height: 30),
      Icon(
        Icons.verified_user_rounded,
        size: 68,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(height: 18),
      Text(
        strings.text('authenticator_ready'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: Text(strings.text('done')),
      ),
    ],
  );

  Future<void> _start() async {
    if (_accountName.text.trim().isEmpty || _password.text.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final login = await widget.controller.startLogin(
        accountName: _accountName.text.trim(),
        password: _password.text,
      );
      _password.clear();
      _loginSession = login;
      if (login.guardTypes.contains(2)) {
        _guardType = 2;
        setState(() => _step = _EnrollStep.guard);
      } else if (login.guardTypes.contains(3)) {
        _guardType = 3;
        setState(() => _step = _EnrollStep.guard);
      } else if (login.guardTypes.contains(4)) {
        _guardType = 4;
        setState(() => _step = _EnrollStep.guard);
      } else {
        await _poll();
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitGuard() async {
    final login = _loginSession;
    if (login == null || _guardCode.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.controller.submitLoginGuard(
        session: login,
        code: _guardCode.text,
        codeType: _guardType,
      );
      await _poll();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _poll() async {
    final login = _loginSession;
    if (login == null) return;
    setState(() {
      _step = _EnrollStep.polling;
      _busy = true;
      _error = null;
    });
    try {
      final tokens = await widget.controller.pollLogin(login);
      final draft = await widget.controller.beginEnrollment(
        accountName: _accountName.text.trim(),
        tokens: tokens,
      );
      _draft = draft;
      if (mounted) setState(() => _step = _EnrollStep.recovery);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _step = _EnrollStep.guard;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finalize() async {
    final draft = _draft;
    if (draft == null || _smsCode.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.controller.finalizeEnrollment(
        draft: draft,
        smsCode: _smsCode.text,
      );
      if (mounted) setState(() => _step = _EnrollStep.done);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      for (
        var index = 0;
        index < _EnrollStep.values.length;
        index++
      ) ...<Widget>[
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            height: index == step ? 4 : 3,
            decoration: BoxDecoration(
              color: index <= step
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        if (index < _EnrollStep.values.length - 1) const SizedBox(width: 6),
      ],
    ],
  );
}
