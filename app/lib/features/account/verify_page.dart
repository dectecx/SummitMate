import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../shared/auth_flow.dart';
import '../../shared/auth_messages.dart';

/// Enter the 6-digit code that was emailed. Signing in happens as soon as it is correct.
class VerifyPage extends ConsumerStatefulWidget {
  const VerifyPage({super.key, required this.email, required this.next});
  final String email;
  final String next;

  @override
  ConsumerState<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends ConsumerState<VerifyPage> {
  static const _cooldown = 60;
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _info;
  int _wait = _cooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _wait = _cooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _wait--);
      if (_wait <= 0) t.cancel();
    });
  }

  Future<void> _submit() async {
    final code = _code.text.trim();
    if (code.length != 6) {
      setState(() => _error = '請輸入 6 位數驗證碼');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(authRepositoryProvider).verifyEmail(email: widget.email, code: code);
      if (!mounted) return;
      await finishSignIn(context, ref, next: widget.next, discardedLocalData: result.discardedLocalData);
    } on Object catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _error = null;
      _info = null;
    });
    try {
      await ref.read(authRepositoryProvider).resendVerification(widget.email);
      if (!mounted) return;
      setState(() => _info = '已重新寄出驗證碼');
      _startCooldown();
    } on Object catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('驗證 Email')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('我們寄了一組 6 位數驗證碼到\n${widget.email}', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            TextField(
              controller: _code,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(letterSpacing: 8),
              decoration: const InputDecoration(hintText: '000000'),
              onSubmitted: (_) => _submit(),
            ),
            FormErrorText(_error),
            if (_info != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_info!)),
            const SizedBox(height: 24),
            BusyFilledButton(label: '驗證並登入', busy: _busy, onPressed: _submit),
            const SizedBox(height: 8),
            TextButton(onPressed: _wait > 0 ? null : _resend, child: Text(_wait > 0 ? '$_wait 秒後可重新寄送' : '重新寄送驗證碼')),
          ],
        ),
      ),
    );
  }
}
