import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/auth/auth_cubit.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/common/password_strength_indicator.dart';

/// 修改密碼畫面
/// 允許已登入的使用者變更密碼。
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _scrollController = ScrollController();

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  double _passwordStrength = 0; // 0.0 to 1.0
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_onPasswordChanged);
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    final password = _newPasswordController.text;
    setState(() {
      _passwordStrength = Validators.calculatePasswordStrength(password);
    });
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await context.read<AuthCubit>().changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result.isSuccess) {
        // 顯示成功對話框
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('密碼修改成功'),
              ],
            ),
            content: const Text('您的密碼已成功變更。為確保安全性，系統已註銷之前的認證狀態。'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // 關閉對話框
                  Navigator.pop(context); // 返回設定/側邊欄
                },
                child: const Text('確定'),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? '修改密碼失敗';
        });
        _scrollToTop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      _scrollToTop();
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('修改密碼'),
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
                const SizedBox(height: 12),
                Text(
                  '為保障您的帳號安全，變更密碼需要先輸入目前的密碼進行驗證。',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),

                // 錯誤訊息提示
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
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
                          child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700)),
                        ),
                      ],
                    ),
                  ),

                // 舊密碼欄位
                TextFormField(
                  controller: _oldPasswordController,
                  obscureText: _obscureOldPassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: '目前密碼',
                    prefixIcon: const Icon(Icons.lock_open_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureOldPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscureOldPassword = !_obscureOldPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '請輸入目前的密碼';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 新密碼欄位
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: '新密碼',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                    ),
                  ),
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 8),

                // 新密碼強度指示器
                if (_newPasswordController.text.isNotEmpty) ...[
                  PasswordStrengthIndicator(strength: _passwordStrength),
                  const SizedBox(height: 16),
                ] else
                  const SizedBox(height: 16),

                // 確認新密碼欄位
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleChangePassword(),
                  decoration: InputDecoration(
                    labelText: '確認新密碼',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '請確認新密碼';
                    }
                    if (value != _newPasswordController.text) {
                      return '密碼不一致';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // 確定變更按鈕
                FilledButton(
                  onPressed: _isLoading ? null : _handleChangePassword,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('確定變更密碼', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
