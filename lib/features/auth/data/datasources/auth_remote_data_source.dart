import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserLookup?> lookupByName(String name);
  Future<UserModel> signIn({
    required String name,
    required String password,
    required String entityType,
    required String entityId,
  });
  Future<UserModel> setFirstPassword({
    required String appUserId,
    required String entityType,
    required String name,
    required String password,
    required UserRole role,
  });
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _supabase;

  AuthRemoteDataSourceImpl(this._supabase);

  @override
  Future<UserLookup?> lookupByName(String name) async {
    try {
      final result = await _supabase.rpc(
        'lookup_user_by_name',
        params: {'p_name': name.trim()},
      ) as List<dynamic>;

      if (result.isEmpty) return null;
      final row = result.first as Map<String, dynamic>;
      final entityType = row['entity_type'] as String;
      return UserLookup(
        id: row['entity_id'] as String,
        entityType: entityType,
        role: UserRoleExtension.fromEntityType(entityType),
        hasPassword: row['has_password'] as bool? ?? false,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel> signIn({
    required String name,
    required String password,
    required String entityType,
    required String entityId,
  }) async {
    try {
      final email = _buildEmail(entityType, entityId);
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw const AppAuthException(message: 'كلمة المرور غير صحيحة');
      }
      return UserModel(
        id: response.user!.id,
        email: '',
        fullName: name.trim(),
        role: UserRoleExtension.fromEntityType(entityType),
        createdAt: DateTime.now(),
      );
    } on AppAuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw AppAuthException(message: _mapAuthError(e.message));
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel> setFirstPassword({
    required String appUserId,
    required String entityType,
    required String name,
    required String password,
    required UserRole role,
  }) async {
    try {
      // Call the Edge Function which uses the service-role admin API —
      // this bypasses email provider settings and creates a confirmed user.
      final fnResponse = await _supabase.functions.invoke(
        'set-first-password',
        body: {
          'entity_id': appUserId,
          'entity_type': entityType,
          'name': name,
          'password': password,
        },
      );

      final body = fnResponse.data as Map<String, dynamic>?;
      if (fnResponse.status != 200 || body?['success'] != true) {
        final errMsg = body?['error'] as String? ?? 'فشل إنشاء الحساب';
        throw AppAuthException(message: _mapAuthError(errMsg));
      }

      // Sign in immediately to establish the session
      final signIn = await _supabase.auth.signInWithPassword(
        email: _buildEmail(entityType, appUserId),
        password: password,
      );
      if (signIn.user == null) {
        throw const AppAuthException(message: 'فشل تسجيل الدخول بعد إنشاء كلمة المرور');
      }
      return UserModel(
        id: signIn.user!.id,
        email: '',
        fullName: name.trim(),
        role: role,
        createdAt: DateTime.now(),
      );
    } on AppAuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw AppAuthException(message: _mapAuthError(e.message));
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) return null;

      final result = await _supabase.rpc(
        'get_user_by_auth_id',
        params: {'p_auth_id': authUser.id},
      ) as List<dynamic>;

      if (result.isEmpty) return null;
      final row = result.first as Map<String, dynamic>;
      final entityType = row['entity_type'] as String;
      return UserModel(
        id: authUser.id,
        email: '',
        fullName: row['name'] as String,
        role: UserRoleExtension.fromEntityType(entityType),
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<UserModel?> get authStateChanges =>
      _supabase.auth.onAuthStateChange.asyncMap((event) async {
        if (event.session?.user == null) return null;
        try {
          return await getCurrentUser();
        } catch (_) {
          return null;
        }
      });

  String _buildEmail(String entityType, String entityId) =>
      '${entityType}_$entityId@masaar.app';

  String _mapAuthError(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid login') || m.contains('invalid_credentials') || m.contains('invalid credentials')) {
      return 'كلمة المرور غير صحيحة';
    }
    if (m.contains('already registered') || m.contains('user already exists')) {
      return 'هذا الحساب مسجل مسبقًا';
    }
    if (m.contains('password should be') || m.contains('weak_password') || m.contains('password is too')) {
      return 'كلمة المرور قصيرة جدًا (8 أحرف على الأقل)';
    }
    if (m.contains('email not confirmed') || m.contains('email_not_confirmed')) {
      return 'الحساب غير مفعّل، تواصلي مع الإدارة';
    }
    if (m.contains('email signups are disabled') || m.contains('email_provider_disabled') || m.contains('signups not allowed')) {
      return 'خدمة التسجيل معطّلة، تواصلي مع الإدارة';
    }
    if (m.contains('rate limit') || m.contains('too many requests')) {
      return 'محاولات كثيرة جداً، حاولي لاحقاً';
    }
    return 'كلمة المرور غير صحيحة';
  }
}
