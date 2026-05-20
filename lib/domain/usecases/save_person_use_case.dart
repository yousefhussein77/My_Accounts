import 'package:my_accounts/domain/models/debt_person.dart';
import 'package:my_accounts/domain/repositories/debt_repository.dart';
import 'package:uuid/uuid.dart';

class SavePersonInput {
  const SavePersonInput({
    required this.userId,
    this.personId,
    required this.name,
    this.phone = '',
    this.note = '',
    this.existingPerson,
  });

  final String userId;
  final String? personId;
  final String name;
  final String phone;
  final String note;
  final DebtPerson? existingPerson;
}

class SavePersonUseCase {
  SavePersonUseCase(this._repository);

  final DebtRepository _repository;
  final Uuid _uuid = const Uuid();

  Future<void> execute(SavePersonInput input) async {
    final existing = input.existingPerson;
    final person = DebtPerson(
      id: input.personId ?? _uuid.v4(),
      name: input.name,
      phone: input.phone,
      note: input.note,
      isFavorite: existing?.isFavorite ?? false,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
    await _repository.savePerson(input.userId, person);
  }
}
