import 'package:my_accounts/core/constants/app_constants.dart';
import 'package:my_accounts/core/utils/app_error.dart';
import 'package:my_accounts/core/widgets/app_brand_logo.dart';
import 'package:my_accounts/presentation/shared/app_providers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _backupBusy = false;
  bool _restoreBusy = false;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final backupMetaText = _buildBackupMetaText(settings);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: const [
            AppBrandLogo(size: 32),
            SizedBox(width: 10),
            Text('الإعدادات'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: settings.themeMode,
                  onChanged: (v) => controller.setThemeMode(v!),
                  title: const Text('الوضع الفاتح'),
                  secondary: const Icon(LucideIcons.sun),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: settings.themeMode,
                  onChanged: (v) => controller.setThemeMode(v!),
                  title: const Text('الوضع الداكن'),
                  secondary: const Icon(LucideIcons.moon),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.database),
                  title: const Text('إنشاء نسخة احتياطية'),
                  subtitle: const Text(
                    'ينصح بحفظ النسخة خارج الجهاز (Drive / USB / Telegram Saved).',
                  ),
                  trailing: FilledButton(
                    onPressed: _backupBusy ? null : _createBackup,
                    child: Text(_backupBusy ? 'جارٍ...' : 'نسخ'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.download),
                  title: const Text('استعادة نسخة احتياطية'),
                  subtitle: const Text('ستستبدل البيانات الحالية بالكامل.'),
                  trailing: FilledButton(
                    onPressed: _restoreBusy ? null : _restoreBackup,
                    child: Text(_restoreBusy ? 'جارٍ...' : 'استعادة'),
                  ),
                ),
              ],
            ),
          ),
          if (backupMetaText != null) ...[
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(LucideIcons.clock3),
                title: const Text('آخر نسخة احتياطية'),
                subtitle: Text(backupMetaText),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Card(
            child: ListTile(
              leading: Icon(LucideIcons.languages),
              title: Text('تبديل اللغة'),
              subtitle: Text('جاهز لإضافة English لاحقًا'),
            ),
          ),
          const SizedBox(height: 14),
          const Card(
            child: ListTile(
              leading: Icon(LucideIcons.badgeCheck),
              title: Text('الحقوق'),
              subtitle: Text('© جميع الحقوق محفوظة'),
              trailing: Text(
                AppConstants.copyrightOwner,
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackup() async {
    final password = await _askPassword(
      title: 'تشفير النسخة (اختياري)',
      message:
          'أدخل كلمة مرور لتشفير النسخة، أو اتركها فارغة لإنشاء نسخة عادية.',
      optional: true,
    );
    if (!mounted) return;
    if (password == null) return;

    setState(() => _backupBusy = true);
    try {
      final path = await ref.read(createBackupUseCaseProvider).execute(
            password: password.isEmpty ? null : password,
          );
      await ref.read(settingsControllerProvider.notifier).setLastBackupMeta(
            at: DateTime.now(),
            path: path,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إنشاء النسخة في: $path')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppError.message(error))),
      );
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _restoreBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الاستعادة'),
        content: const Text(
          'سيتم استبدال بيانات التطبيق الحالية بالكامل. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['db', 'mabk'],
      allowMultiple: false,
    );
    final filePath = result?.files.single.path;
    if (filePath == null || filePath.trim().isEmpty) return;
    final lowerPath = filePath.toLowerCase();
    if (!lowerPath.endsWith('.db') && !lowerPath.endsWith('.mabk')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('امتداد الملف غير مدعوم')),
      );
      return;
    }

    String? password;
    if (lowerPath.endsWith('.mabk')) {
      password = await _askPassword(
        title: 'كلمة مرور النسخة',
        message: 'أدخل كلمة المرور لفك تشفير النسخة واستعادتها.',
        optional: false,
      );
      if (!mounted) return;
      if (password == null || password.isEmpty) return;
    }

    setState(() => _restoreBusy = true);
    try {
      await ref.read(restoreBackupUseCaseProvider).execute(
            filePath,
            password: password,
          );
      await ref.read(authControllerProvider.notifier).load();
      await ref.read(debtControllerProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت الاستعادة بنجاح')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppError.message(error))),
      );
    } finally {
      if (mounted) setState(() => _restoreBusy = false);
    }
  }

  Future<String?> _askPassword({
    required String title,
    required String message,
    required bool optional,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                labelText: optional ? 'كلمة المرور (اختياري)' : 'كلمة المرور',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  String? _buildBackupMetaText(AppSettings settings) {
    final at = settings.lastBackupAt;
    final path = settings.lastBackupPath;
    if (at == null || path == null || path.trim().isEmpty) return null;

    final atText = DateFormat('yyyy/MM/dd - HH:mm', 'ar').format(at);
    return '$atText\n$path';
  }
}
