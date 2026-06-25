import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SetFirstPasswordUseCase extends UseCase<UserEntity, SetFirstPasswordParams> {
  final AuthRepository repository;
  SetFirstPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SetFirstPasswordParams params) =>
      repository.setFirstPassword(
        appUserId: params.appUserId,
        entityType: params.entityType,
        name: params.name,
        password: params.password,
        role: params.role,
      );
}

class SetFirstPasswordParams extends Equatable {
  final String appUserId;
  final String entityType;
  final String name;
  final String password;
  final UserRole role;

  const SetFirstPasswordParams({
    required this.appUserId,
    required this.entityType,
    required this.name,
    required this.password,
    required this.role,
  });

  @override
  List<Object> get props => [appUserId, entityType, name, password, role];
}
