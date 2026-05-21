import 'package:my_accounts/core/constants/app_constants.dart';
import 'package:my_accounts/core/utils/app_error.dart';
import 'package:my_accounts/core/widgets/app_brand_logo.dart';
import 'package:my_accounts/domain/models/backup_file_info.dart';
import 'package:my_accounts/presentation/shared/app_providers.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _backupCanceled = '__backup_canceled__';
  static const _minBackupPasswordLength = 8;

  bool _backupBusy = false;
  bool _restoreBusy = false;
  bool _validateBusy = false;
  Future<List<BackupFileInfo>>? _defaultBackupsFuture;
  Future<String>? _defaultBackupDirectoryFuture;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final backupReminderText = _buildBackupReminderText(settings);
    final backupMetaText = _buildBackupMetaText(settings);
    final restoreMetaText = _buildRestoreMetaText(settings);
    final safetyBackupMetaText = _buildSafetyBackupMetaText(settings);
    final defaultBackupsFuture = _defaultBackupsFuture ??= ref
        .read(listBackupsUseCaseProvider)
        .execute();
    final defaultBackupDirectoryFuture = _defaultBackupDirectoryFuture ??=
        _resolveDefaultBackupDirectoryPath();

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
            child: ListTile(
              leading: Icon(
                settings.themeMode == ThemeMode.dark
                    ? LucideIcons.moon
                    : LucideIcons.sun,
              ),
              title: const Text('الوضع الداكن'),
              trailing: Switch(
                value: settings.themeMode == ThemeMode.dark,
                onChanged: (v) => controller.setThemeMode(
                  v ? ThemeMode.dark : ThemeMode.light,
                ),
              ),
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
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.checkCircle),
                  title: const Text('فحص ملف نسخة'),
                  subtitle: const Text(
                    'يتحقق من صلاحية النسخة بدون استبدال البيانات.',
                  ),
                  trailing: FilledButton(
                    onPressed: _validateBusy ? null : _validateExternalBackup,
                    child: Text(_validateBusy ? 'جارٍ...' : 'فحص'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _BackupReminderSettingsCard(
            reminderDays: settings.reminderDays,
            onChanged: controller.setReminderDays,
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
          const SizedBox(height: 10),
          _DefaultBackupFolderCard(
            directoryPathFuture: defaultBackupDirectoryFuture,
            onCopy: _copyPath,
          ),
          const SizedBox(height: 10),
          _DefaultBackupsCard(
            backupsFuture: defaultBackupsFuture,
            onRefresh: _refreshDefaultBackups,
            onCopy: _copyPath,
            onRestore: _restoreBackupFromManagedFile,
            onDelete: _deleteManagedBackup,
            onValidate: _validateManagedBackup,
          ),
          if (backupMetaText != null) ...[
            const SizedBox(height: 10),
            _BackupMetaCard(
              icon: LucideIcons.clock3,
              title: 'آخر نسخة احتياطية',
              text: backupMetaText,
              onCopy: () => _copyPath(settings.lastBackupPath),
            ),
          ],
          if (restoreMetaText != null) ...[
            const SizedBox(height: 10),
            _BackupMetaCard(
              icon: LucideIcons.history,
              title: 'آخر استعادة',
              text: restoreMetaText,
              onCopy: () => _copyPath(settings.lastRestorePath),
            ),
          ],
          if (safetyBackupMetaText != null) ...[
            const SizedBox(height: 10),
            _BackupMetaCard(
              icon: LucideIcons.shieldCheck,
              title: 'نسخة أمان قبل الاستعادة',
              text: safetyBackupMetaText,
              onCopy: () => _copyPath(settings.lastSafetyBackupPath),
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
                textDirection: ui.TextDirection.ltr,
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
          content: Text(
            'كلمة مرور النسخة المشفرة يجب أن تكون 8 أحرف على الأقل',
          ),
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
      final path = await ref
          .read(createBackupUseCaseProvider)
          .execute(
            directoryPath: directoryPath,
            password: password.isEmpty ? null : password,
          );
      await ref
          .read(settingsControllerProvider.notifier)
          .setLastBackupMeta(at: DateTime.now(), path: path);
      _refreshDefaultBackups();
      if (!mounted) return;
      _showPathSnackBar(message: 'تم إنشاء النسخة في: $path', path: path);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppError.message(error))));
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _restoreBackup() async {
    final confirmed = await _confirmRestoreIntent();
    if (!confirmed) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['db', 'mabk'],
      allowMultiple: false,
    );
    final filePath = result?.files.single.path;
    if (filePath == null || filePath.trim().isEmpty) return;

    await _restoreBackupFile(filePath);
  }

  Future<void> _restoreBackupFromManagedFile(String filePath) async {
    final confirmed = await _confirmRestoreIntent();
    if (!confirmed) return;
    await _restoreBackupFile(filePath);
  }

  Future<void> _deleteManagedBackup(BackupFileInfo backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف النسخة'),
        content: Text('سيتم حذف النسخة:\n${backup.fileName}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(deleteBackupUseCaseProvider).execute(backup.path);
      await ref
          .read(settingsControllerProvider.notifier)
          .clearFileMetaForPath(backup.path);
      _refreshDefaultBackups();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف النسخة')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppError.message(error))));
    }
  }

  Future<void> _validateManagedBackup(BackupFileInfo backup) async {
    await _validateBackupFile(backup.path, encrypted: backup.isEncrypted);
  }

  Future<void> _validateExternalBackup() async {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('امتداد الملف غير مدعوم')));
      return;
    }

    await _validateBackupFile(filePath, encrypted: lowerPath.endsWith('.mabk'));
  }

  Future<void> _validateBackupFile(
    String filePath, {
    required bool encrypted,
  }) async {
    String? password;
    if (encrypted) {
      password = await _askPassword(
        title: 'كلمة مرور النسخة',
        message: 'أدخل كلمة المرور لفحص النسخة المشفرة بدون استعادتها.',
        optional: false,
      );
      if (!mounted) return;
      if (password == null || password.isEmpty) return;
    }

    setState(() => _validateBusy = true);
    try {
      await ref
          .read(validateBackupUseCaseProvider)
          .execute(filePath, password: password);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('النسخة صالحة للاستعادة')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppError.message(error))));
    } finally {
      if (mounted) setState(() => _validateBusy = false);
    }
  }

  Future<bool> _confirmRestoreIntent() async {
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
    return confirmed == true;
  }

  Future<void> _restoreBackupFile(String filePath) async {
    final lowerPath = filePath.toLowerCase();
    if (!lowerPath.endsWith('.db') && !lowerPath.endsWith('.mabk')) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('امتداد الملف غير مدعوم')));
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
      final restoreResult = await ref
          .read(restoreBackupUseCaseProvider)
          .execute(filePath, password: password);
      final safetyBackupPath = restoreResult.safetyBackupPath;
      await ref
          .read(settingsControllerProvider.notifier)
          .setLastRestoreMeta(at: DateTime.now(), path: filePath);
      if (safetyBackupPath != null) {
        await ref
            .read(settingsControllerProvider.notifier)
            .setLastSafetyBackupMeta(
              at: DateTime.now(),
              path: safetyBackupPath,
            );
      }
      await ref.read(authControllerProvider.notifier).load();
      await ref.read(debtControllerProvider.notifier).refresh();
      _refreshDefaultBackups();
      if (!mounted) return;
      final safetyText = safetyBackupPath == null
          ? ''
          : '\nتم حفظ نسخة أمان: ${p.basename(safetyBackupPath)}';
      _showPathSnackBar(
        message: 'تمت الاستعادة بنجاح$safetyText',
        path: safetyBackupPath ?? filePath,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppError.message(error))));
    } finally {
      if (mounted) setState(() => _restoreBusy = false);
    }
  }

  void _refreshDefaultBackups() {
    if (!mounted) return;
    setState(() {
      _defaultBackupsFuture = ref.read(listBackupsUseCaseProvider).execute();
    });
  }

  Future<void> _copyPath(String? path) async {
    if (path == null || path.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: path));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم نسخ المسار')));
  }

  void _showPathSnackBar({required String message, required String path}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'نسخ',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: path));
          },
        ),
      ),
    );
  }

  Future<String> _resolveDefaultBackupDirectoryPath() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return p.join(appDocDir.path, 'backups');
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
    return _buildFileMetaText(settings.lastBackupAt, settings.lastBackupPath);
  }

  String? _buildRestoreMetaText(AppSettings settings) {
    return _buildFileMetaText(settings.lastRestoreAt, settings.lastRestorePath);
  }

  String? _buildSafetyBackupMetaText(AppSettings settings) {
    return _buildFileMetaText(
      settings.lastSafetyBackupAt,
      settings.lastSafetyBackupPath,
    );
  }

  String? _buildFileMetaText(DateTime? at, String? path) {
    if (at == null || path == null || path.trim().isEmpty) return null;

    final atText = DateFormat('yyyy/MM/dd - HH:mm', 'ar').format(at);
    return '$atText\n$path';
  }

  String? _buildBackupReminderText(AppSettings settings) {
    final lastBackupAt = settings.lastBackupAt;
    final reminderDays = settings.reminderDays.clamp(1, 365).toInt();
    if (lastBackupAt == null) {
      return 'لم يتم إنشاء نسخة احتياطية بعد. احفظ نسخة خارج الجهاز لتجنب فقدان البيانات.';
    }

    final elapsed = DateTime.now().difference(lastBackupAt);
    if (elapsed < Duration(days: reminderDays)) return null;

    final days = elapsed.inDays;
    return 'آخر نسخة احتياطية كانت قبل $days يوم. فترة التذكير الحالية $reminderDays يوم.';
  }
}

class _DefaultBackupsCard extends StatelessWidget {
  const _DefaultBackupsCard({
    required this.backupsFuture,
    required this.onRefresh,
    required this.onCopy,
    required this.onRestore,
    required this.onDelete,
    required this.onValidate,
  });

  final Future<List<BackupFileInfo>> backupsFuture;
  final VoidCallback onRefresh;
  final ValueChanged<String?> onCopy;
  final ValueChanged<String> onRestore;
  final ValueChanged<BackupFileInfo> onDelete;
  final ValueChanged<BackupFileInfo> onValidate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(LucideIcons.database),
            title: const Text('النسخ داخل التطبيق'),
            subtitle: const Text(
              'آخر النسخ المحفوظة في مجلد التطبيق الافتراضي.',
            ),
            trailing: IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh),
              onPressed: onRefresh,
            ),
          ),
          const Divider(height: 1),
          FutureBuilder<List<BackupFileInfo>>(
            future: backupsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: const Text('تعذر تحميل النسخ المحفوظة'),
                  subtitle: Text(AppError.message(snapshot.error!)),
                );
              }

              final backups = snapshot.data ?? const <BackupFileInfo>[];
              if (backups.isEmpty) {
                return const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('لا توجد نسخ محفوظة داخل التطبيق'),
                );
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'عدد النسخ: ${backups.length}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ),
                  for (var i = 0; i < backups.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _DefaultBackupTile(
                      backup: backups[i],
                      onCopy: () => onCopy(backups[i].path),
                      onRestore: () => onRestore(backups[i].path),
                      onDelete: () => onDelete(backups[i]),
                      onValidate: () => onValidate(backups[i]),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DefaultBackupTile extends StatelessWidget {
  const _DefaultBackupTile({
    required this.backup,
    required this.onCopy,
    required this.onRestore,
    required this.onDelete,
    required this.onValidate,
  });

  final BackupFileInfo backup;
  final VoidCallback onCopy;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat(
      'yyyy/MM/dd - HH:mm',
      'ar',
    ).format(backup.modifiedAt);
    final size = _formatBytes(backup.sizeBytes);
    final type = backup.isSafetyCopy
        ? 'نسخة أمان'
        : (backup.isEncrypted ? 'مشفرة' : 'عادية');

    return ListTile(
      leading: Icon(
        backup.isEncrypted ? Icons.lock_outline : LucideIcons.database,
      ),
      title: Text(
        backup.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textDirection: ui.TextDirection.ltr,
      ),
      subtitle: Text('$date\n$type - $size'),
      isThreeLine: true,
      trailing: SizedBox(
        width: 132,
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.end,
          children: [
            IconButton(
              tooltip: 'نسخ المسار',
              icon: const Icon(LucideIcons.copy),
              onPressed: onCopy,
            ),
            IconButton(
              tooltip: 'فحص النسخة',
              icon: const Icon(LucideIcons.shieldCheck),
              onPressed: onValidate,
            ),
            IconButton(
              tooltip: 'استعادة',
              icon: const Icon(LucideIcons.refreshCcw),
              onPressed: onRestore,
            ),
            IconButton(
              tooltip: 'حذف',
              icon: const Icon(LucideIcons.trash2),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}

class _BackupReminderSettingsCard extends StatelessWidget {
  const _BackupReminderSettingsCard({
    required this.reminderDays,
    required this.onChanged,
  });

  final int reminderDays;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeDays = reminderDays.clamp(1, 365).toInt();

    return Card(
      child: ListTile(
        leading: const Icon(LucideIcons.bell),
        title: const Text('تذكير النسخ الاحتياطي'),
        subtitle: Text('ينبهك إذا مر $safeDays يوم بدون نسخة جديدة.'),
        trailing: PopupMenuButton<int>(
          tooltip: 'تغيير الفترة',
          initialValue: safeDays,
          onSelected: onChanged,
          itemBuilder: (_) => const [
            PopupMenuItem(value: 3, child: Text('3 أيام')),
            PopupMenuItem(value: 7, child: Text('7 أيام')),
            PopupMenuItem(value: 14, child: Text('14 يوم')),
            PopupMenuItem(value: 30, child: Text('30 يوم')),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$safeDays'),
              const SizedBox(width: 4),
              const Icon(LucideIcons.chevronDown, size: 18),
            ],
          ),
        ),
      ),
    );
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

class _BackupMetaCard extends StatelessWidget {
  const _BackupMetaCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.onCopy,
  });

  final IconData icon;
  final String title;
  final String text;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: SelectableText(text, textDirection: ui.TextDirection.ltr),
        trailing: IconButton(
          tooltip: 'نسخ المسار',
          icon: const Icon(LucideIcons.copy),
          onPressed: onCopy,
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
                Text('إرشادات النسخ الاحتياطي', style: textTheme.titleMedium),
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
              text:
                  'جرّب الاستعادة فقط من ملف تثق به، لأن البيانات الحالية ستستبدل.',
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultBackupFolderCard extends StatelessWidget {
  const _DefaultBackupFolderCard({
    required this.directoryPathFuture,
    required this.onCopy,
  });

  final Future<String>? directoryPathFuture;
  final ValueChanged<String?> onCopy;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: directoryPathFuture,
      builder: (context, snapshot) {
        final title = snapshot.hasError
            ? 'تعذر تحديد المجلد الافتراضي'
            : 'مجلد النسخ الاحتياطي الافتراضي';
        final subtitleText = snapshot.hasError
            ? AppError.message(snapshot.error!)
            : snapshot.connectionState == ConnectionState.waiting
            ? 'جارٍ التحميل...'
            : snapshot.data ?? 'غير متوفر';

        return Card(
          child: ListTile(
            leading: const Icon(LucideIcons.folderOpen),
            title: Text(title),
            subtitle: SelectableText(
              subtitleText,
              textDirection: ui.TextDirection.ltr,
            ),
            trailing: IconButton(
              tooltip: 'نسخ المسار',
              icon: const Icon(LucideIcons.copy),
              onPressed: snapshot.hasData ? () => onCopy(snapshot.data) : null,
            ),
          ),
        );
      },
    );
  }
}

class _BackupTip extends StatelessWidget {
  const _BackupTip({required this.icon, required this.text});

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
