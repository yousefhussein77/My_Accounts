import 'package:my_accounts/core/utils/app_validators.dart';
import 'package:my_accounts/core/utils/app_error.dart';
import 'package:my_accounts/presentation/auth/auth_form_shell.dart';
import 'package:my_accounts/presentation/shared/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .register(_name.text, _email.text, _password.text);
    if (!mounted) return;
    final state = ref.read(authControllerProvider);
    state.whenOrNull(
      data: (_) => context.go('/app'),
      error: (error, _) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppError.message(error)))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return AuthFormShell(
      title: 'إنشاء حساب',
      subtitle: 'حساب محلي جاهز للاستبدال لاحقًا بـ Firebase أو API.',
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  prefixIcon: Icon(LucideIcons.user),
                  labelText: 'الاسم',
                ),
                validator: AppValidators.name,
              ),
              const SizedBox(height: 14),
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
                validator: AppValidators.passwordStrong,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(LucideIcons.lock),
                  labelText: 'تأكيد كلمة المرور',
                ),
                validator: (v) => (v ?? '') == _password.text
                    ? null
                    : 'تأكيد كلمة المرور غير مطابق',
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: auth.isLoading ? null : _submit,
                icon: const Icon(LucideIcons.userPlus),
                label: const Text('إنشاء الحساب'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('لديك حساب؟ تسجيل الدخول'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
