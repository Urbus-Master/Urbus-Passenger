enum UserRole {
  admin,
  operator,
  user;

  String get displayName => switch (this) {
    UserRole.admin    => 'Administrador',
    UserRole.operator => 'Operador',
    UserRole.user     => 'Ciudadano',
  };
}

class UserModel {
  final int id;
  final String email;
  final String name;
  final bool isActive;
  final DateTime createdAt;
  final UserRole role;
  final String? avatarUrl;
  final String? address;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.isActive,
    required this.createdAt,
    this.role = UserRole.user,
    this.avatarUrl,
    this.address,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      isActive: json['status'] == 'active',
      createdAt: DateTime.now(),
      role: json['role'] == 'admin' ? UserRole.admin : UserRole.user,
      avatarUrl: json['avatarUrl'],
      address: json['contact'],
    );
  }
}
