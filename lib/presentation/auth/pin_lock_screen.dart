import 'package:my_accounts/core/widgets/app_brand_logo.dart';
import 'package:my_accounts/core/utils/app_error.dart';
import 'package:my_accounts/presentation/shared/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  final _pin = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final value = _pin.text.trim();
    if (value.length < 4 || !RegExp(r'^\d+$').hasMatch(value)) return;

    final pinState = ref.read(pinControllerProvider);
    if (pinState.isLocked && pinState.lockedUntil != null) {
      final seconds = pinState.lockedUntil!
          .difference(DateTime.now())
          .inSeconds
          .clamp(1, 9999);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('محاولات كثيرة، حاول بعد $seconds ثانية')));
      return;
    }

    setState(() => _submitting = true);
    bool ok = false;
    try {
      ok = await ref.read(pinControllerProvider.notifier).verify(value);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppError.message(error))),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      context.go('/app');
      return;
    }

    final nextState = ref.read(pinControllerProvider);
    if (nextState.isLocked && nextState.lockedUntil != null) {
      final seconds = nextState.lockedUntil!
          .difference(DateTime.now())
          .inSeconds
          .clamp(1, 9999);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم قفل الإدخال مؤقتًا لمدة $seconds ثانية')),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('رمز PIN غير صحيح')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.75),
                  radius: 1.2,
                  colors: [
                    colors.primary.withOpacity(0.12),
                    colors.surface,
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, -1.05),
            child: Container(
              width: 520,
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withOpacity(0.05),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppBrandLogo(size: 88),
                      const SizedBox(height: 14),
                      Text(
                        'قفل التطبيق',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text('أدخل رمز PIN للمتابعة'),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _pin,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'PIN',
                          prefixIcon: Icon(LucideIcons.keyRound),
                          counterText: '',
                        ),
                        onSubmitted: (_) => _unlock(),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _submitting ? null : _unlock,
                        icon: _submitting
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(LucideIcons.unlock),
                        label: const Text('فتح'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
