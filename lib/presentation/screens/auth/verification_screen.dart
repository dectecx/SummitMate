import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';

class VerificationScreen extends StatefulWidget {
  final String email;

  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _canResend = false;
  int _countdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _canResend = false;
      _countdown = 30;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  void _handleVerify(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().verifyEmail(widget.email, _codeController.text.trim());
  }

  void _handleResend(BuildContext context) {
    context.read<AuthCubit>().resendCode(widget.email);
    _startTimer();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('驗證成功'),
        content: const Text('您的 Email 已成功驗證！'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(true); // Close screen with success
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthOperationSuccess) {
          if (state.message.contains('驗證成功')) {
            _showSuccessDialog();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        } else if (state is AuthError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: AppTheme.primaryColor,
          appBar: AppBar(
            title: const Text('驗證信箱'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  const Icon(Icons.mark_email_read_outlined, size: 80, color: Colors.white),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    '輸入驗證碼',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    '我們已發送 6 位數驗證碼至\n${widget.email}',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Form
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Code Input
                          TextFormField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                            decoration: InputDecoration(
                              hintText: '000000',
                              counterText: '',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '請輸入驗證碼';
                              }
                              if (value.length != 6) {
                                return '請輸入 6 位數驗證碼';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Verify Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton(
                              onPressed: isLoading ? null : () => _handleVerify(context),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('驗證', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Resend Button
                          TextButton(
                            onPressed: (_canResend && !isLoading) ? () => _handleResend(context) : null,
                            child: Text(
                              _canResend ? '重新發送驗證碼' : '重新發送 (${_countdown}s)',
                              style: TextStyle(color: _canResend ? AppTheme.primaryColor : Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
