import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/lookup_user_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LookupUserByNameUseCase _lookupByName;
  final SignInUseCase _signIn;
  final SetFirstPasswordUseCase _setFirstPassword;
  final SignOutUseCase _signOut;
  final AuthRepository _authRepository;

  AuthCubit({
    required LookupUserByNameUseCase lookupByName,
    required SignInUseCase signIn,
    required SetFirstPasswordUseCase setFirstPassword,
    required SignOutUseCase signOut,
    required AuthRepository authRepository,
  })  : _lookupByName = lookupByName,
        _signIn = signIn,
        _setFirstPassword = setFirstPassword,
        _signOut = signOut,
        _authRepository = authRepository,
        super(const AuthInitial()) {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    emit(const AuthLoading());
    final result = await _authRepository.getCurrentUser();
    result.fold(
      (_) => emit(const AuthUnauthenticated()),
      (user) => user != null
          ? emit(AuthAuthenticated(user))
          : emit(const AuthUnauthenticated()),
    );
  }

  Future<void> lookupByName(String name) async {
    if (name.trim().isEmpty) return;
    emit(const AuthLoading());
    final result = await _lookupByName(name.trim());
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (lookup) {
        if (lookup == null) {
          emit(const AuthError('الاسم غير مسجل، تواصلي مع الإدارة'));
        } else if (lookup.hasPassword) {
          emit(AuthNameFound(appUserId: lookup.id, entityType: lookup.entityType, name: name.trim(), role: lookup.role));
        } else {
          emit(AuthNeedsPassword(appUserId: lookup.id, entityType: lookup.entityType, name: name.trim(), role: lookup.role));
        }
      },
    );
  }

  Future<void> signIn({
    required String name,
    required String password,
    required String entityType,
    required String entityId,
  }) async {
    emit(const AuthLoading());
    final result = await _signIn(SignInParams(
      name: name,
      password: password,
      entityType: entityType,
      entityId: entityId,
    ));
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> setFirstPassword({
    required String appUserId,
    required String entityType,
    required String name,
    required String password,
    required UserRole role,
  }) async {
    emit(const AuthLoading());
    final result = await _setFirstPassword(SetFirstPasswordParams(
      appUserId: appUserId,
      entityType: entityType,
      name: name,
      password: password,
      role: role,
    ));
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> signOut() async {
    emit(const AuthLoading());
    final result = await _signOut();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  void resetToNameEntry() => emit(const AuthUnauthenticated());
}
