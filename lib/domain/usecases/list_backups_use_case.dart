import 'package:my_accounts/data/services/local_backup_service.dart';
import 'package:my_accounts/domain/models/backup_file_info.dart';

class ListBackupsUseCase {
  ListBackupsUseCase(this._service);

  final LocalBackupService _service;

  Future<List<BackupFileInfo>> execute() {
    return _service.defaultBackups();
  }
}
