import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserLookup?>> lookupByName(String name);

  Future<Either<Failure, UserEntity>> signIn({
    required String name,
    required String password,
    required String entityType,
    required String entityId,
  });

  Future<Either<Failure, UserEntity>> setFirstPassword({
    required String appUserId,
    required String entityType,
    required String name,
    required String password,
    required UserRole role,
  });

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, UserEntity?>> getCurrentUser();

  Stream<UserEntity?> get authStateChanges;
}
