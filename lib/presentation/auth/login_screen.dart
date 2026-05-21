import 'package:my_accounts/core/utils/app_validators.dart';
import 'package:my_accounts/core/utils/app_error.dart';
import 'package:my_accounts/presentation/auth/auth_form_shell.dart';
import 'package:my_accounts/presentation/shared/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .login(_email.text, _password.text);
    final state = ref.read(authControllerProvider);
    if (!mounted) return;
    state.whenOrNull(
      data: (user) {
        if (user != null) context.go('/app');
      },
      error: (error, _) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppError.message(error)))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return AuthFormShell(
      title: 'مرحبًا بعودتك',
      subtitle: 'سجل الدخول لإدارة الديون والمدفوعات بثقة.',
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  prefixIcon: Icon(LucideIcons.mail),
                  labelText: 'البريد الإلكتروني',
                ),
                validator: AppValidators.email,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(LucideIcons.lock),
                  labelText: 'كلمة المرور',
                ),
                validator: AppValidators.passwordLogin,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: const Text('نسيت كلمة المرور؟'),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: auth.isLoading ? null : _submit,
                icon: auth.isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.logIn),
                label: const Text('دخول'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/register'),
                child: const Text('ليس لديك حساب؟ إنشاء حساب'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
