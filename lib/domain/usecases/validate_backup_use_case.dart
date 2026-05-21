import 'package:my_accounts/data/services/local_backup_service.dart';

class ValidateBackupUseCase {
  ValidateBackupUseCase(this._service);

  final LocalBackupService _service;

  Future<void> execute(String backupPath, {String? password}) {
    return _service.validateBackup(backupPath, password: password);
  }
}
