import 'package:my_accounts/data/services/local_backup_service.dart';

class CreateBackupUseCase {
  CreateBackupUseCase(this._service);

  final LocalBackupService _service;

  Future<String> execute({String? directoryPath}) {
    return _service.createBackup(directoryPath: directoryPath);
  }
}
