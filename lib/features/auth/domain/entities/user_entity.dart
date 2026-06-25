import 'package:equatable/equatable.dart';

enum UserRole { student, teacher, parent }

extension UserRoleExtension on UserRole {
  String get label => switch (this) {
        UserRole.student => 'طالبة',
        UserRole.teacher => 'معلمة',
        UserRole.parent => 'ولية أمر',
      };

  String get value => switch (this) {
        UserRole.student => 'student',
        UserRole.teacher => 'teacher',
        UserRole.parent => 'parent',
      };

  // Maps DB entity_type ('student','instructor','guardian') → UserRole
  static UserRole fromEntityType(String entityType) => switch (entityType) {
        'instructor' => UserRole.teacher,
        'guardian' => UserRole.parent,
        _ => UserRole.student,
      };

  // Legacy: maps role value string ('student','teacher','parent') → UserRole
  static UserRole fromString(String value) => switch (value) {
        'teacher' => UserRole.teacher,
        'parent' => UserRole.parent,
        _ => UserRole.student,
      };
}

class UserLookup {
  final String id;          // entity_id in the DB
  final String entityType;  // 'student' | 'instructor' | 'guardian'
  final UserRole role;
  final bool hasPassword;
  const UserLookup({
    required this.id,
    required this.entityType,
    required this.role,
    required this.hasPassword,
  });
}

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? avatarUrl;
  final String? phone;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    this.phone,
    required this.createdAt,
  });

  String get greeting {
    final hour = DateTime.now().hour;
    return hour < 12 ? 'صباح الخير' : 'مساء الخير';
  }

  @override
  List<Object?> get props => [id, email, fullName, role, avatarUrl, phone];
}
