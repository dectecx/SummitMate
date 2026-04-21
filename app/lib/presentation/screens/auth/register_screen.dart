import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart'
    show AuthState, AuthLoading, AuthAuthenticated, AuthError, AuthRequiresVerification;
import '../../cubits/settings/settings_cubit.dart';
import 'verification_screen.dart';

/// Register Screen
/// Allows new users to create an account.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _scrollController = ScrollController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Avatar selection
  final List<String> _avatarOptions = ['🐻', '🦊', '🐼', '🐨', '🦁', '🐸', '🐢', '🐙'];
  String _selectedAvatar = '🐻';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthCubit>().register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _displayNameController.text.trim(),
      avatar: _selectedAvatar,
    );
  }

  Future<void> _handleVerification(String email) async {
    // 註冊成功，跳轉至驗證頁面
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => VerificationScreen(email: email)),
    );

    if (verified == true && mounted) {
      // 驗證成功，返回登入畫面讓使用者自行登入
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('註冊成功！請登入您的帳號')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Direct login after register (rare but possible)
          if (state.userName != null) {
            context.read<SettingsCubit>().updateUsername(state.userName!);
          }
          if (mounted) Navigator.pop(context);
        } else if (state is AuthRequiresVerification) {
          _handleVerification(state.email);
        } else if (state is AuthError) {
          if (mounted) {
            _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
          }
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final errorMessage = (state is AuthError) ? state.message : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('建立帳號'),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
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
                    // Avatar Selection
                    Text('選擇頭像', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: _avatarOptions.map((avatar) {
                        final isSelected = avatar == _selectedAvatar;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedAvatar = avatar),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? theme.colorScheme.primaryContainer : Colors.grey.shade100,
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
                            ),
                            child: Text(avatar, style: const TextStyle(fontSize: 28)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

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

                    // Display Name Field
                    TextFormField(
                      controller: _displayNameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: '顯示名稱',
                        prefixIcon: Icon(Icons.person_outlined),
                        border: OutlineInputBorder(),
                        hintText: '例如：小明',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '請輸入顯示名稱';
                        }
                        if (value.length < 2) {
                          return '顯示名稱至少需要 2 個字';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

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
                        if (!value.contains('@') || !value.contains('.')) {
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
                      textInputAction: TextInputAction.next,
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
                        if (value.length < 8) {
                          return '密碼至少需要 8 個字元';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleRegister(),
                      decoration: InputDecoration(
                        labelText: '確認密碼',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '請確認密碼';
                        }
                        if (value != _passwordController.text) {
                          return '密碼不一致';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    const SizedBox(height: 24),

                    // Register Button
                    FilledButton(
                      onPressed: isLoading ? null : _handleRegister,
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('建立帳號', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 16),

                    // Back to Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('已經有帳號？'),
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('返回登入')),
                      ],
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
