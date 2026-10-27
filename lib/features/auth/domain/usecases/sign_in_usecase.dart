import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase extends UseCase<UserEntity, SignInParams> {
  final AuthRepository repository;
  SignInUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignInParams params) =>
      repository.signIn(
        name: params.name,
        password: params.password,
        entityType: params.entityType,
        entityId: params.entityId,
      );
}

class SignInParams extends Equatable {
  final String name;
  final String password;
  final String entityType;
  final String entityId;
  const SignInParams({
    required this.name,
    required this.password,
    required this.entityType,
    required this.entityId,
  });

  @override
  List<Object> get props => [name, password, entityType, entityId];
}
