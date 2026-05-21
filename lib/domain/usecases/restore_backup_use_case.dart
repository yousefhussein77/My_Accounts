import 'package:my_accounts/data/services/local_backup_service.dart';

class RestoreBackupUseCase {
  RestoreBackupUseCase(this._service);

  final LocalBackupService _service;

  Future<RestoreBackupResult> execute(
    String backupFilePath, {
    String? password,
  }) {
    return _service.restoreBackup(
      backupFilePath,
      password: password,
    );
  }
}
