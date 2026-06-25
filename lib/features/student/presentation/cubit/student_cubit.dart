import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/halaqah_entity.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/entities/student_dashboard_entity.dart';
import '../../../evaluation/domain/entities/evaluation_entity.dart';
import 'student_state.dart';

class StudentCubit extends Cubit<StudentState> {
  final SupabaseClient _supabase;

  StudentCubit(this._supabase) : super(const StudentInitial());

  Future<void> loadDashboard() async {
    emit(const StudentLoading());
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(const StudentError('لم يتم العثور على المستخدم'));
        return;
      }

      // Load student data, halaqah, lessons and evaluations in parallel
      final results = await Future.wait([
        _loadHalaqah(userId),
        _loadLessons(userId),
        _loadAttendanceCount(userId),
        _loadLatestEvaluation(userId),
      ]);

      final halaqah = results[0] as HalaqahEntity?;
      final lessonsData = results[1] as Map<String, dynamic>;
      final attendanceCounts = results[2] as Map<String, int>;
      final latestEval = results[3] as EvaluationEntity?;

      final dashboard = StudentDashboardEntity(
        halaqah: halaqah,
        recentLessons: lessonsData['recent'] as List<LessonEntity>,
        nextLesson: lessonsData['next'] as LessonEntity?,
        totalLessons: attendanceCounts['total'] ?? 0,
        attendedLessons: attendanceCounts['attended'] ?? 0,
        latestEvaluation: latestEval,
      );

      emit(StudentLoaded(dashboard));
    } catch (e) {
      emit(StudentError(e.toString()));
    }
  }

  Future<HalaqahEntity?> _loadHalaqah(String userId) async {
    try {
      final data = await _supabase
          .from('students')
          .select('halaqah_groups(id, name, description, location, schedule_day, schedule_time, teachers(profiles(full_name, avatar_url)))')
          .eq('id', userId)
          .maybeSingle();

      if (data?['halaqah_groups'] == null) return null;
      final g = data!['halaqah_groups'] as Map<String, dynamic>;
      final teacher = (g['teachers'] as Map?)?.cast<String, dynamic>();
      final profile = (teacher?['profiles'] as Map?)?.cast<String, dynamic>();

      return HalaqahEntity(
        id: g['id'] as String,
        name: g['name'] as String,
        description: g['description'] as String?,
        teacherName: profile?['full_name'] as String?,
        teacherAvatarUrl: profile?['avatar_url'] as String?,
        location: g['location'] as String?,
        scheduleDay: g['schedule_day'] as String?,
        scheduleTime: g['schedule_time'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _loadLessons(String userId) async {
    try {
      final studentData = await _supabase
          .from('students')
          .select('group_id')
          .eq('id', userId)
          .maybeSingle();

      if (studentData?['group_id'] == null) {
        return {'recent': <LessonEntity>[], 'next': null};
      }

      final groupId = studentData!['group_id'] as String;
      final lessonsData = await _supabase
          .from('lessons')
          .select()
          .eq('group_id', groupId)
          .order('lesson_date', ascending: false)
          .limit(10);

      final lessons = (lessonsData as List).map((l) => LessonEntity(
            id: l['id'] as String,
            groupId: l['group_id'] as String,
            title: l['title'] as String,
            description: l['description'] as String?,
            lessonDate: DateTime.parse(l['lesson_date'] as String),
            durationMinutes: l['duration_minutes'] as int? ?? 60,
            status: l['status'] as String? ?? 'scheduled',
          )).toList();

      final nextLesson = lessons.where((l) => l.isUpcoming).lastOrNull;
      return {'recent': lessons.take(5).toList(), 'next': nextLesson};
    } catch (_) {
      return {'recent': <LessonEntity>[], 'next': null};
    }
  }

  Future<Map<String, int>> _loadAttendanceCount(String userId) async {
    try {
      final attended = await _supabase
          .from('attendances')
          .select('id')
          .eq('student_id', userId)
          .eq('status', 'present');
      final all = await _supabase
          .from('attendances')
          .select('id')
          .eq('student_id', userId);
      return {
        'attended': (attended as List).length,
        'total': (all as List).length,
      };
    } catch (_) {
      return {'attended': 0, 'total': 0};
    }
  }

  Future<EvaluationEntity?> _loadLatestEvaluation(String userId) async {
    try {
      final data = await _supabase
          .from('evaluations')
          .select('*, teachers(profiles(full_name))')
          .eq('student_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) return null;
      final teacher = (data['teachers'] as Map?)?.cast<String, dynamic>();
      final profile = (teacher?['profiles'] as Map?)?.cast<String, dynamic>();

      return EvaluationEntity(
        id: data['id'] as String,
        studentId: userId,
        studentName: '',
        teacherId: data['teacher_id'] as String,
        teacherName: profile?['full_name'] as String?,
        type: EvaluationTypeExtension.fromString(data['type'] as String? ?? 'memorization'),
        score: (data['score'] as num).toDouble(),
        maxScore: (data['max_score'] as num?)?.toDouble() ?? 100,
        notes: data['notes'] as String?,
        evaluatedDate: DateTime.parse(data['evaluated_date'] as String),
      );
    } catch (_) {
      return null;
    }
  }
}
