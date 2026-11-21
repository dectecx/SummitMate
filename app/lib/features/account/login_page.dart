import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../core/auth/auth_api.dart';
import '../../core/providers.dart';
import '../../shared/auth_flow.dart';
import '../../shared/auth_messages.dart';

/// Sign in. When [email] is given (the session expired) the email is fixed, so the data that
/// has not been uploaded yet stays with the same account.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, required this.next, this.email});
  final String next;
  final String? email;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(authRepositoryProvider);
    final email = _email.text.trim().toLowerCase();
    try {
      final result = await repo.login(email: email, password: _password.text);
      if (!mounted) return;
      await finishSignIn(context, ref, next: widget.next, discardedLocalData: result.discardedLocalData);
    } on AuthException catch (e) {
      if (e.code == 'email_not_verified') {
        // Registered but never verified: send a fresh code and continue there.
        try {
          await repo.resendVerification(email);
        } on Object {
          // The verify page offers "resend" as well.
        }
        if (mounted) context.pushReplacement(Routes.withQuery(Routes.verify, {'email': email, 'next': widget.next}));
        return;
      }
      if (mounted) setState(() => _error = authErrorMessage(e));
    } on Object catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.email != null;
    return Scaffold(
      appBar: AppBar(title: const Text('登入')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (locked)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text('請用同一個帳號重新登入，才不會遺失還沒上傳的資料。'),
              ),
            Form(
              key: _form,
              child: AutofillGroup(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _email,
                      readOnly: locked,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: validateEmail,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _password,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      validator: (v) => (v ?? '').isEmpty ? '請輸入密碼' : null,
                      onSubmitted: _submit,
                    ),
                  ],
                ),
              ),
            ),
            FormErrorText(_error),
            const SizedBox(height: 24),
            BusyFilledButton(label: '登入', busy: _busy, onPressed: _submit),
            if (!locked) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.pushReplacement(Routes.withQuery(Routes.register, {'next': widget.next})),
                child: const Text('還沒有帳號？註冊'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
