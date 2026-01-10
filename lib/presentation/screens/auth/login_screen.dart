import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart'
    show AuthState, AuthLoading, AuthAuthenticated, AuthError, AuthRequiresVerification;

import '../../providers/settings_provider.dart';
import 'register_screen.dart';
import 'verification_screen.dart';

/// Login Screen
/// Allows users to login with email and password.
/// Supports offline warning when user tries to logout while offline.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().login(_emailController.text.trim(), _passwordController.text);
  }

  void _handleRegister() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  Future<void> _handleVerification(String email) async {
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => VerificationScreen(email: email)),
    );

    if (verified == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('驗證成功！歡迎回來')));
      context.read<AuthCubit>().checkAuthStatus(); // Refresh status to login
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Sync SettingsProvider with user profile
          if (state.userName != null && state.userName!.isNotEmpty) {
            context.read<SettingsProvider>().updateUsername(state.userName!);
          }
          // Avatar is not in AuthAuthenticated state, might be missing update.
          // But AuthProvider bridge calls validateSession which fetches full profile.
          // SettingsProvider might need another way to get avatar if not in state.
          // AuthCubit could define Avatar in state, or we rely on AuthProvider bridge.

          // Show offline mode notification if applicable
          if (state.isOffline) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('已使用離線模式登入，部分功能可能受限'),
                backgroundColor: Colors.orange.shade700,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } else if (state is AuthError) {
          if (mounted) {
            _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
          }
        } else if (state is AuthRequiresVerification) {
          _handleVerification(state.email);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final errorMessage = (state is AuthError) ? state.message : null;

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),

                    // Logo / Title
                    Icon(Icons.terrain, size: 80, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      '歡迎回來',
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '登入以同步您的登山行程',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Error Message
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(errorMessage, style: TextStyle(color: Colors.red.shade700)),
                            ),
                          ],
                        ),
                      ),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '請輸入 Email';
                        }
                        if (!value.contains('@')) {
                          return '請輸入有效的 Email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                      decoration: InputDecoration(
                        labelText: '密碼',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '請輸入密碼';
                        }
                        if (value.length < 6) {
                          return '密碼至少需要 6 個字元';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    FilledButton(
                      onPressed: isLoading ? null : _handleLogin,
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('登入', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 16),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('還沒有帳號？'),
                        TextButton(onPressed: _handleRegister, child: const Text('立即註冊')),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Skip Login (Guest Mode)
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('訪客模式'),
                            content: const Text('訪客模式下，您的資料將不會同步到雲端。\n\n是否繼續？'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(ctx); // Close dialog
                                  context.read<AuthCubit>().loginAsGuest();
                                },
                                child: const Text('繼續'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('以訪客身分繼續'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
