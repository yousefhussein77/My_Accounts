import 'package:my_accounts/presentation/auth/auth_form_shell.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AuthFormShell(
      title: 'استعادة كلمة المرور',
      subtitle: 'هذا التطبيق يعمل محليًا على جهازك ولا يرسل بريد استعادة تلقائيًا.',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.shieldAlert, color: colors.primary),
              const SizedBox(height: 12),
              Text(
                'لأمان بياناتك، لا يمكن استعادة كلمة المرور محليًا بدون آلية تحقق إضافية أو نسخة احتياطية.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'إذا نسيت كلمة المرور، استخدم نسخة احتياطية موثوقة أو أنشئ حسابًا محليًا جديدًا.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => context.go('/login'),
          icon: const Icon(LucideIcons.arrowRight),
          label: const Text('العودة لتسجيل الدخول'),
        ),
      ],
    );
  }
}
