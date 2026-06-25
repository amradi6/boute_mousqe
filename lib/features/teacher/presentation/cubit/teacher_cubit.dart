import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'teacher_state.dart';

class TeacherCubit extends Cubit<TeacherState> {
  final SupabaseClient _supabase;

  TeacherCubit(this._supabase) : super(const TeacherInitial());

  Future<void> loadDashboard() async {
    emit(const TeacherLoading());
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(const TeacherError('لم يتم العثور على المستخدم'));
        return;
      }

      final results = await Future.wait([
        _loadGroups(userId),
        _loadStudentCount(userId),
        _loadTodayLessons(userId),
        _loadRecentEvaluations(userId),
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

  Future<List<Map<String, dynamic>>> _loadGroups(String userId) async {
    try {
      final data = await _supabase
          .from('halaqah_groups')
          .select()
          .eq('teacher_id', userId);
      return (data as List).map((g) => g as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> _loadStudentCount(String userId) async {
    try {
      final groups = await _supabase
          .from('halaqah_groups')
          .select('id')
          .eq('teacher_id', userId);
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

  Future<List<Map<String, dynamic>>> _loadTodayLessons(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final groups = await _supabase
          .from('halaqah_groups')
          .select('id')
          .eq('teacher_id', userId);
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

  Future<List<Map<String, dynamic>>> _loadRecentEvaluations(String userId) async {
    try {
      final data = await _supabase
          .from('evaluations')
          .select('*, students(profiles(full_name))')
          .eq('teacher_id', userId)
          .order('created_at', ascending: false)
          .limit(5);
      return (data as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }
}
