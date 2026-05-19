import 'package:debt_ledger_app/core/utils/app_error.dart';
import 'package:debt_ledger_app/core/utils/app_validators.dart';
import 'package:debt_ledger_app/presentation/shared/app_header.dart';
import 'package:debt_ledger_app/presentation/shared/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _showSetPinDialog(BuildContext context, WidgetRef ref) async {
    final pin = TextEditingController();
    final confirm = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('تعيين رمز PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pin,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'PIN من 4 إلى 6 أرقام',
                  counterText: '',
                ),
              ),
              TextField(
                controller: confirm,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'تأكيد PIN',
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final value = pin.text.trim();
                final pinError = AppValidators.pin(value);
                if (pinError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(pinError)),
                  );
                  return;
                }
                if (value != confirm.text.trim()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تأكيد PIN غير مطابق')),
                  );
                  return;
                }
                try {
                  await ref.read(pinControllerProvider.notifier).setPin(value);
                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حفظ PIN بنجاح')),
                    );
                  }
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppError.message(error))),
                  );
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    pin.dispose();
    confirm.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final pinState = ref.watch(pinControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            AppHeader(
              title: 'الأمان',
              subtitle: user?.email ?? 'حساب محلي',
              trailing: IconButton.filledTonal(
                onPressed: () => context.push('/settings'),
                icon: const Icon(LucideIcons.settings),
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      child: Text((user?.name ?? 'U').characters.first),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'مستخدم حساباتي',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pinState.hasPin
                                ? 'PIN مفعل لحماية الدخول للتطبيق.'
                                : 'يمكنك تفعيل PIN لقفل التطبيق برمز سريع.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const _Tile(
              icon: LucideIcons.shieldCheck,
              title: 'قفل التطبيق',
              subtitle: 'مفعل عبر تسجيل الدخول.',
            ),
            _Tile(
              icon: LucideIcons.lock,
              title: 'رمز PIN',
              subtitle: pinState.hasPin ? 'مفعل' : 'غير مفعل',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _showSetPinDialog(context, ref),
              icon: const Icon(LucideIcons.keyRound),
              label: Text(pinState.hasPin ? 'تغيير PIN' : 'تفعيل PIN'),
            ),
            if (pinState.hasPin) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await ref.read(pinControllerProvider.notifier).clearPin();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إلغاء PIN')),
                      );
                    }
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppError.message(error))),
                    );
                  }
                },
                icon: const Icon(LucideIcons.unlock),
                label: const Text('إلغاء PIN'),
              ),
            ],
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  ref.read(pinControllerProvider.notifier).lock();
                  await ref.read(authControllerProvider.notifier).logout();
                  if (!context.mounted) return;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) context.go('/login');
                  });
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppError.message(error))),
                  );
                }
              },
              icon: const Icon(LucideIcons.logOut),
              label: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
