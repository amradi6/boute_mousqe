import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.role,
    super.avatarUrl,
    super.phone,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        role: UserRoleExtension.fromString(json['role'] as String? ?? 'student'),
        avatarUrl: json['avatar_url'] as String?,
        phone: json['phone'] as String?,
        createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String(),
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'role': role.value,
        'avatar_url': avatarUrl,
        'phone': phone,
        'created_at': createdAt.toIso8601String(),
      };

  factory UserModel.fromEntity(UserEntity entity) => UserModel(
        id: entity.id,
        email: entity.email,
        fullName: entity.fullName,
        role: entity.role,
        avatarUrl: entity.avatarUrl,
        phone: entity.phone,
        createdAt: entity.createdAt,
      );
}
