import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'teacher_state.dart';

class TeacherCubit extends Cubit<TeacherState> {
  final SupabaseClient _supabase;

  TeacherCubit(this._supabase) : super(const TeacherInitial());

  // Returns the instructor's entity_id (instructors.id), not the auth user ID
  String? get _entityId =>
      _supabase.auth.currentUser?.userMetadata?['entity_id'] as String?;

  Future<void> loadDashboard() async {
    emit(const TeacherLoading());
    try {
      final entityId = _entityId;
      if (entityId == null) {
        emit(const TeacherError('لم يتم العثور على المستخدم'));
        return;
      }

      final results = await Future.wait([
        _loadGroups(entityId),
        _loadStudentCount(entityId),
        _loadTodayLessons(entityId),
        _loadRecentEvaluations(entityId),
      ]);

      emit(TeacherLoaded({
        'groups': results[0],
        'studentCount': results[1],
        'todayLessons': results[2],
        'recentEvaluations': results[3],
      }));
    } catch (e) {
      emit(TeacherError(e.toString()));
    }
  }

  Future<List<Map<String, dynamic>>> _loadGroups(String entityId) async {
    try {
      final data = await _supabase
          .from('halaqah_groups')
          .select()
          .eq('teacher_id', entityId);
      return (data as List).map((g) => g as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> _loadStudentCount(String entityId) async {
    try {
      final groups = await _supabase
          .from('halaqah_groups')
          .select('id')
          .eq('teacher_id', entityId);
      if ((groups as List).isEmpty) return 0;
      final groupIds = groups.map((g) => g['id']).toList();
      final students = await _supabase
          .from('students')
          .select('id')
          .inFilter('group_id', groupIds);
      return (students as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> _loadTodayLessons(String entityId) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final groups = await _supabase
          .from('halaqah_groups')
          .select('id')
          .eq('teacher_id', entityId);
      if ((groups as List).isEmpty) return [];
      final groupIds = groups.map((g) => g['id']).toList();
      final data = await _supabase
          .from('lessons')
          .select('*, halaqah_groups(name)')
          .inFilter('group_id', groupIds)
          .eq('lesson_date', today);
      return (data as List).map((l) => l as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadRecentEvaluations(String entityId) async {
    try {
      final data = await _supabase
          .from('evaluations')
          .select('*, students(name)')
          .eq('teacher_id', entityId)
          .order('created_at', ascending: false)
          .limit(5);
      return (data as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }
}
