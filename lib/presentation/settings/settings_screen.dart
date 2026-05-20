import 'package:my_accounts/core/constants/app_constants.dart';
import 'package:my_accounts/core/utils/app_error.dart';
import 'package:my_accounts/core/widgets/app_brand_logo.dart';
import 'package:my_accounts/presentation/shared/app_providers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path/path.dart' as p;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _backupCanceled = '__backup_canceled__';
  static const _backupReminderThreshold = Duration(days: 7);
  static const _minBackupPasswordLength = 8;

  bool _backupBusy = false;
  bool _restoreBusy = false;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final backupReminderText = _buildBackupReminderText(settings);
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
          if (backupReminderText != null) ...[
            const SizedBox(height: 10),
            _BackupReminderCard(
              message: backupReminderText,
              onCreateBackup: _backupBusy ? null : _createBackup,
            ),
          ],
          const SizedBox(height: 10),
          const _BackupGuidanceCard(),
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
    if (password.isEmpty) {
      final confirmedPlainBackup = await _confirmPlainBackup();
      if (!mounted) return;
      if (!confirmedPlainBackup) return;
    }
    if (password.isNotEmpty && password.length < _minBackupPasswordLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('كلمة مرور النسخة المشفرة يجب أن تكون 8 أحرف على الأقل'),
        ),
      );
      return;
    }
    if (password.isNotEmpty) {
      final confirmation = await _askPassword(
        title: 'تأكيد كلمة المرور',
        message: 'أعد إدخال كلمة مرور النسخة المشفرة للتأكد منها.',
        optional: false,
      );
      if (!mounted) return;
      if (confirmation == null) return;
      if (confirmation != password) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('كلمتا المرور غير متطابقتين')),
        );
        return;
      }
    }

    final directoryPath = await _askBackupDirectory();
    if (!mounted) return;
    if (directoryPath == _backupCanceled) return;

    setState(() => _backupBusy = true);
    try {
      final path = await ref.read(createBackupUseCaseProvider).execute(
            directoryPath: directoryPath,
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

    final confirmedFile = await _confirmRestoreFile(filePath);
    if (!mounted) return;
    if (!confirmedFile) return;

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

  Future<bool> _confirmPlainBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('نسخة غير مشفرة'),
        content: const Text(
          'سيتم إنشاء نسخة احتياطية بدون كلمة مرور. استخدم هذا الخيار فقط إذا كنت ستحفظها في مكان آمن.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<bool> _confirmRestoreFile(String filePath) async {
    final fileName = p.basename(filePath);
    final isEncrypted = filePath.toLowerCase().endsWith('.mabk');
    final backupType = isEncrypted ? 'مشفرة' : 'غير مشفرة';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد ملف الاستعادة'),
        content: Text(
          'سيتم استعادة النسخة:\n$fileName\n\nنوع النسخة: $backupType\nسيتم استبدال البيانات الحالية بالكامل.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<String?> _askBackupDirectory() async {
    final shouldChoose = await showDialog<bool?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('مكان حفظ النسخة'),
        content: const Text(
          'يمكن حفظ النسخة في المسار الافتراضي، أو اختيار مجلد خارجي يسهل نقله إلى Drive أو USB.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('افتراضي'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('اختيار مجلد'),
          ),
        ],
      ),
    );

    if (shouldChoose == null) return _backupCanceled;
    if (!shouldChoose) return null;

    final selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'اختر مكان حفظ النسخة الاحتياطية',
    );
    return selectedDirectory?.trim().isEmpty == true ? null : selectedDirectory;
  }

  String? _buildBackupMetaText(AppSettings settings) {
    final at = settings.lastBackupAt;
    final path = settings.lastBackupPath;
    if (at == null || path == null || path.trim().isEmpty) return null;

    final atText = DateFormat('yyyy/MM/dd - HH:mm', 'ar').format(at);
    return '$atText\n$path';
  }

  String? _buildBackupReminderText(AppSettings settings) {
    final lastBackupAt = settings.lastBackupAt;
    if (lastBackupAt == null) {
      return 'لم يتم إنشاء نسخة احتياطية بعد. احفظ نسخة خارج الجهاز لتجنب فقدان البيانات.';
    }

    final elapsed = DateTime.now().difference(lastBackupAt);
    if (elapsed < _backupReminderThreshold) return null;

    final days = elapsed.inDays;
    return 'آخر نسخة احتياطية كانت قبل $days يوم. يفضّل إنشاء نسخة جديدة وحفظها خارج الجهاز.';
  }
}

class _BackupReminderCard extends StatelessWidget {
  const _BackupReminderCard({
    required this.message,
    required this.onCreateBackup,
  });

  final String message;
  final VoidCallback? onCreateBackup;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.errorContainer,
      child: ListTile(
        leading: Icon(
          LucideIcons.alertTriangle,
          color: colorScheme.onErrorContainer,
        ),
        title: Text(
          'تذكير النسخ الاحتياطي',
          style: TextStyle(color: colorScheme.onErrorContainer),
        ),
        subtitle: Text(
          message,
          style: TextStyle(color: colorScheme.onErrorContainer),
        ),
        trailing: TextButton(
          onPressed: onCreateBackup,
          child: const Text('نسخ الآن'),
        ),
      ),
    );
  }
}

class _BackupGuidanceCard extends StatelessWidget {
  const _BackupGuidanceCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_upload_outlined),
                const SizedBox(width: 10),
                Text(
                  'إرشادات النسخ الاحتياطي',
                  style: textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _BackupTip(
              icon: Icons.drive_file_move_outline,
              text: 'انقل النسخة إلى Google Drive أو USB أو جهاز آخر.',
            ),
            const SizedBox(height: 8),
            const _BackupTip(
              icon: Icons.lock_outline,
              text: 'استخدم كلمة مرور قوية للنسخ المهمة ولا تفقدها.',
            ),
            const SizedBox(height: 8),
            const _BackupTip(
              icon: Icons.restore_outlined,
              text: 'جرّب الاستعادة فقط من ملف تثق به، لأن البيانات الحالية ستستبدل.',
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupTip extends StatelessWidget {
  const _BackupTip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}
