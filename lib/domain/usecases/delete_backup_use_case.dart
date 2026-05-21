import 'package:my_accounts/data/services/local_backup_service.dart';

class DeleteBackupUseCase {
  DeleteBackupUseCase(this._service);

  final LocalBackupService _service;

  Future<void> execute(String backupPath) {
    return _service.deleteDefaultBackup(backupPath);
  }
}
