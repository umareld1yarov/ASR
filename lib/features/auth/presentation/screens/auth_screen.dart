import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_background.dart';
import '../../application/auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    bool success = false;

    if (_isSignUp) {
      success = await controller.signUp(
        _emailController.text,
        _passwordController.text,
        name: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : null,
      );
    } else {
      success = await controller.signIn(
        _emailController.text,
        _passwordController.text,
      );
    }

    if (mounted) {
      final state = ref.read(authControllerProvider);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF06B6D4),
            content: Text(
              _isSignUp
                  ? 'auth.register_success'.tr()
                  : 'auth.login_success'.tr(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
        Navigator.of(context).pop();
      } else if (state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(state.errorMessage!),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Верхний AppBar с кнопкой назад
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Иконка и заголовки
                      Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF06B6D4).withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock_person_outlined,
                            size: 34,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _isSignUp ? 'auth.register_title'.tr() : 'auth.login_title'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'auth.login_subtitle'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white60,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Табы переключения Режим Входа / Регистрации
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isSignUp = false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !_isSignUp
                                        ? const Color(0xFF06B6D4)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: !_isSignUp
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'auth.sign_in_tab'.tr(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: !_isSignUp
                                            ? Colors.white
                                            : Colors.white54,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isSignUp = true),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _isSignUp
                                        ? const Color(0xFF06B6D4)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: _isSignUp
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'auth.sign_up_tab'.tr(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: _isSignUp
                                            ? Colors.white
                                            : Colors.white54,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Форма ввода
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (_isSignUp) ...[
                              TextFormField(
                                controller: _nameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'auth.name_label'.tr(),
                                  labelStyle: const TextStyle(color: Colors.white54),
                                  prefixIcon: const Icon(Icons.person_outline,
                                      color: Colors.white54),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.05),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide:
                                        const BorderSide(color: Colors.white12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide:
                                        const BorderSide(color: Colors.white12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF06B6D4), width: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'auth.email_required'.tr();
                                }
                                if (!val.contains('@')) {
                                  return 'auth.email_invalid'.tr();
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'auth.email_label'.tr(),
                                labelStyle: const TextStyle(color: Colors.white54),
                                prefixIcon: const Icon(Icons.email_outlined,
                                    color: Colors.white54),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.white12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.white12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF06B6D4), width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'auth.password_required'.tr();
                                }
                                if (val.length < 6) {
                                  return 'auth.password_min_length'.tr();
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'auth.password_label'.tr(),
                                labelStyle: const TextStyle(color: Colors.white54),
                                prefixIcon: const Icon(Icons.lock_outline,
                                    color: Colors.white54),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white54,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.white12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.white12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF06B6D4), width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Главная кнопка отправки
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: state.isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF06B6D4),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 2,
                                ),
                                child: state.isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _isSignUp
                                            ? 'auth.sign_up_btn'.tr()
                                            : 'auth.sign_in_btn'.tr(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Разделитель «Или»
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Colors.white12)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'auth.or_quick_login'.tr(),
                              style: const TextStyle(fontSize: 12, color: Colors.white38),
                            ),
                          ),
                          const Expanded(child: Divider(color: Colors.white12)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Кнопка Google
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: state.isLoading
                              ? null
                              : () async {
                                  final success = await ref
                                      .read(authControllerProvider.notifier)
                                      .signInWithGoogle();
                                  if (context.mounted) {
                                    final currentAuthState =
                                        ref.read(authControllerProvider);
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: const Color(0xFF06B6D4),
                                          content: Text(
                                            'auth.login_success'.tr(),
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      );
                                      Navigator.of(context).pop();
                                    } else if (currentAuthState.errorMessage != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: Colors.redAccent,
                                          content: Text(currentAuthState.errorMessage!),
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            backgroundColor: Colors.white.withValues(alpha: 0.04),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: state.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF06B6D4),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.g_mobiledata,
                                        size: 20,
                                        color: Color(0xFFEA4335),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'auth.google_sign_in'.tr(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      // Кнопка Apple (если на iOS или macOS)
                      if (Platform.isIOS || Platform.isMacOS) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: state.isLoading
                                ? null
                                : () async {
                                    final success = await ref
                                        .read(authControllerProvider.notifier)
                                        .signInWithApple();
                                    if (context.mounted) {
                                      final currentAuthState =
                                          ref.read(authControllerProvider);
                                      if (success) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: const Color(0xFF06B6D4),
                                            content: Text(
                                              'auth.login_success'.tr(),
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        );
                                        Navigator.of(context).pop();
                                      } else if (currentAuthState.errorMessage != null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: Colors.redAccent,
                                            content: Text(currentAuthState.errorMessage!),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            icon: const Icon(Icons.apple, size: 22, color: Colors.black),
                            label: Text(
                              'auth.apple_sign_in'.tr(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
