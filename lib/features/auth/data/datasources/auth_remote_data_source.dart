import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserLookup?> lookupByName(String name);
  Future<UserModel> signIn({required String name, required String password});
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
  Future<UserModel> signIn({required String name, required String password}) async {
    try {
      final lookup = await lookupByName(name);
      if (lookup == null) throw const AppAuthException(message: 'الاسم غير مسجل');
      if (!lookup.hasPassword) throw const AppAuthException(message: 'لم يتم تعيين كلمة مرور بعد');

      final email = _buildEmail(lookup.entityType, lookup.id);
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
        role: lookup.role,
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
      final email = _buildEmail(entityType, appUserId);
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name, 'role': role.value},
      );
      if (response.user == null) {
        throw const AppAuthException(message: 'فشل إنشاء الحساب');
      }
      // Link auth user to the entity in user_credentials
      await _supabase.from('user_credentials').insert({
        'entity_id': appUserId,
        'entity_type': entityType,
        'auth_user_id': response.user!.id,
      });
      return UserModel(
        id: response.user!.id,
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
    if (message.contains('Invalid login')) return 'كلمة المرور غير صحيحة';
    if (message.contains('already registered')) return 'هذا الحساب مسجل مسبقًا';
    if (message.contains('Password should be')) return 'كلمة المرور قصيرة جدًا (8 أحرف على الأقل)';
    return 'حدث خطأ في المصادقة';
  }
}
