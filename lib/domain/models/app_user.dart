class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'created_at': createdAt.toIso8601String(),
  };

  factory AppUser.fromMap(Map<String, Object?> map) => AppUser(
    id: map['id'] as String,
    name: map['name'] as String,
    email: map['email'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}
