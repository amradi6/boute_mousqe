import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Name was found in DB and user already has a password — show password field.
class AuthNameFound extends AuthState {
  final String appUserId;
  final String entityType; // 'student' | 'instructor' | 'guardian'
  final String name;
  final UserRole role;
  const AuthNameFound({required this.appUserId, required this.entityType, required this.name, required this.role});

  @override
  List<Object?> get props => [appUserId, entityType, name, role];
}

/// Name was found in DB but no password set yet — show create-password form.
class AuthNeedsPassword extends AuthState {
  final String appUserId;
  final String entityType; // 'student' | 'instructor' | 'guardian'
  final String name;
  final UserRole role;
  const AuthNeedsPassword({required this.appUserId, required this.entityType, required this.name, required this.role});

  @override
  List<Object?> get props => [appUserId, entityType, name, role];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
