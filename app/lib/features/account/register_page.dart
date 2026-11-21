import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../core/auth/auth_api.dart';
import '../../core/providers.dart';
import '../../shared/auth_flow.dart';
import '../../shared/auth_messages.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key, required this.next});
  final String next;

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _emailTaken = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _emailTaken = false;
    });
    final email = _email.text.trim().toLowerCase();
    try {
      await ref.read(authRepositoryProvider).register(email: email, password: _password.text, displayName: _name.text.trim());
      if (mounted) context.pushReplacement(Routes.withQuery(Routes.verify, {'email': email, 'next': widget.next}));
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _error = authErrorMessage(e);
        _emailTaken = e is AuthException && e.code == 'email_already_exists';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('註冊')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Form(
              key: _form,
              child: AutofillGroup(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.nickname],
                      validator: (v) => (v ?? '').trim().isEmpty ? '請輸入暱稱' : ((v ?? '').trim().length > 100 ? '暱稱太長了' : null),
                      decoration: const InputDecoration(labelText: '暱稱', helperText: '隊友會看到這個名字'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
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
                      autofillHints: const [AutofillHints.newPassword],
                      validator: validateNewPassword,
                      onSubmitted: _submit,
                    ),
                  ],
                ),
              ),
            ),
            FormErrorText(_error),
            if (_emailTaken)
              TextButton(
                onPressed: () => context.pushReplacement(Routes.withQuery(Routes.login, {'next': widget.next})),
                child: const Text('改為登入'),
              ),
            const SizedBox(height: 24),
            BusyFilledButton(label: '註冊並寄送驗證碼', busy: _busy, onPressed: _submit),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.pushReplacement(Routes.withQuery(Routes.login, {'next': widget.next})),
              child: const Text('已經有帳號？登入'),
            ),
          ],
        ),
      ),
    );
  }
}
