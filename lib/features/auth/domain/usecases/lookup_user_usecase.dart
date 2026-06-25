import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LookupUserByNameUseCase extends UseCase<UserLookup?, String> {
  final AuthRepository repository;
  LookupUserByNameUseCase(this.repository);

  @override
  Future<Either<Failure, UserLookup?>> call(String name) =>
      repository.lookupByName(name);
}
