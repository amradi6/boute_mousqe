import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, UserLookup?>> lookupByName(String name) async {
    try {
      final result = await remoteDataSource.lookupByName(name);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signIn({
    required String name,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.signIn(name: name, password: password);
      return Right(user);
    } on AppAuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> setFirstPassword({
    required String appUserId,
    required String entityType,
    required String name,
    required String password,
    required UserRole role,
  }) async {
    try {
      final user = await remoteDataSource.setFirstPassword(
        appUserId: appUserId,
        entityType: entityType,
        name: name,
        password: password,
        role: role,
      );
      return Right(user);
    } on AppAuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges => remoteDataSource.authStateChanges;
}
