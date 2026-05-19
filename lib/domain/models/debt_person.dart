class DebtPerson {
  const DebtPerson({
    required this.id,
    required this.name,
    required this.phone,
    required this.note,
    required this.isFavorite,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String note;
  final bool isFavorite;
  final DateTime createdAt;

  DebtPerson copyWith({
    String? name,
    String? phone,
    String? note,
    bool? isFavorite,
  }) =>
      DebtPerson(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        note: note ?? this.note,
        isFavorite: isFavorite ?? this.isFavorite,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'note': note,
        'is_favorite': isFavorite ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory DebtPerson.fromMap(Map<String, Object?> map) => DebtPerson(
        id: map['id'] as String,
        name: map['name'] as String,
        phone: map['phone'] as String? ?? '',
        note: map['note'] as String? ?? '',
        isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
