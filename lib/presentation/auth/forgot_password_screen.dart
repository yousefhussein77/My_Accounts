import 'package:debt_ledger_app/core/utils/app_validators.dart';
import 'package:debt_ledger_app/presentation/auth/auth_form_shell.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormShell(
      title: 'استعادة كلمة المرور',
      subtitle: 'في النسخة المحلية سنعرض رسالة إرشادية بدل إرسال بريد حقيقي.',
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
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تسجيل طلب الاستعادة محليًا'),
                    ),
                  );
                  context.go('/login');
                },
                icon: const Icon(LucideIcons.send),
                label: const Text('إرسال التعليمات'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
