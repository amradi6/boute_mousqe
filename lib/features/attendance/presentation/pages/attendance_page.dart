import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../domain/entities/attendance_entity.dart';

class AttendancePage extends StatefulWidget {
  final bool isTeacher;
  final String? studentId;
  const AttendancePage({super.key, this.isTeacher = false, this.studentId});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _lessons = [];
  List<Map<String, dynamic>> _students = [];
  Map<String, AttendanceStatus> _attendanceMap = {};
  String? _selectedLessonId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String? get _entityId =>
      Supabase.instance.client.auth.currentUser?.userMetadata?['entity_id'] as String?;

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entityId = _entityId;
      if (entityId == null) throw Exception('المستخدم غير موجود');

      if (widget.isTeacher) {
        await _loadTeacherData(entityId);
      } else {
        await _loadStudentAttendance(entityId);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadTeacherData(String entityId) async {
    final groups = await Supabase.instance.client
        .from('halaqah_groups')
        .select('id')
        .eq('teacher_id', entityId);

    if ((groups as List).isEmpty) {
      setState(() => _loading = false);
      return;
    }

    final groupIds = groups.map((g) => g['id']).toList();

    final lessons = await Supabase.instance.client
        .from('lessons')
        .select('id, title, lesson_date, group_id')
        .inFilter('group_id', groupIds)
        .gte('lesson_date', DateTime.now().subtract(const Duration(days: 7)).toIso8601String().substring(0, 10))
        .order('lesson_date', ascending: false);

    setState(() {
      _lessons = (lessons as List).map((l) => l as Map<String, dynamic>).toList();
      if (_lessons.isNotEmpty) _selectedLessonId = _lessons.first['id'] as String;
      _loading = false;
    });

    if (_selectedLessonId != null) {
      await _loadStudentsForLesson(_selectedLessonId!, groupIds);
    }
  }

  Future<void> _loadStudentsForLesson(String lessonId, List groupIds) async {
    setState(() => _loading = true);
    final students = await Supabase.instance.client
        .from('students')
        .select('id, name')
        .inFilter('group_id', groupIds);

    final existing = await Supabase.instance.client
        .from('attendances')
        .select('student_id, status')
        .eq('lesson_id', lessonId);

    final existingMap = <String, String>{};
    for (final a in (existing as List)) {
      existingMap[a['student_id'] as String] = a['status'] as String;
    }

    final map = <String, AttendanceStatus>{};
    final list = <Map<String, dynamic>>[];
    for (final s in (students as List)) {
      final id = s['id'] as String;
      map[id] = AttendanceStatusExtension.fromString(existingMap[id] ?? 'present');
      list.add({'id': id, 'name': s['name'] as String? ?? 'طالبة'});
    }

    setState(() {
      _students = list;
      _attendanceMap = map;
      _loading = false;
    });
  }

  Future<void> _loadStudentAttendance(String userId) async {
    final targetId = widget.studentId ?? userId;
    final records = await Supabase.instance.client
        .from('attendances')
        .select('id, status, lessons(title, lesson_date)')
        .eq('student_id', targetId)
        .order('created_at', ascending: false)
        .limit(30);

    setState(() {
      _lessons = (records as List).map((r) {
        final lesson = (r['lessons'] as Map).cast<String, dynamic>();
        return {
          'id': r['id'],
          'title': lesson['title'],
          'date': lesson['lesson_date'],
          'status': r['status'],
        };
      }).toList();
      _loading = false;
    });
  }

  Future<void> _saveAttendance() async {
    if (_selectedLessonId == null) return;
    setState(() => _saving = true);
    try {
      final records = _attendanceMap.entries.map((e) => {
            'student_id': e.key,
            'lesson_id': _selectedLessonId,
            'status': e.value.value,
            'recorded_by': Supabase.instance.client.auth.currentUser?.id,
          }).toList();

      await Supabase.instance.client.from('attendances').upsert(
            records,
            onConflict: 'student_id,lesson_id',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الحضور بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.isTeacher ? AppStrings.markAttendance : AppStrings.attendanceHistory,
        ),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _loadData)
              : widget.isTeacher
                  ? _buildTeacherView()
                  : _buildStudentView(),
      bottomNavigationBar: widget.isTeacher && _students.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: AppButton(
                label: AppStrings.save,
                onPressed: _saving ? null : _saveAttendance,
                isLoading: _saving,
                icon: Icons.save_outlined,
              ),
            )
          : null,
    );
  }

  Widget _buildTeacherView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_lessons.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedLessonId,
              decoration: const InputDecoration(
                labelText: AppStrings.selectLesson,
                prefixIcon: Icon(Icons.book_outlined),
              ),
              items: _lessons.map((l) => DropdownMenuItem(
                    value: l['id'] as String,
                    child: Text(l['title'] as String? ?? 'درس', style: AppTypography.bodyMedium),
                  )).toList(),
              onChanged: (val) async {
                if (val == null) return;
                setState(() => _selectedLessonId = val);
                final entityId = _entityId ?? '';
                final groups = await Supabase.instance.client
                    .from('halaqah_groups')
                    .select('id')
                    .eq('teacher_id', entityId);
                await _loadStudentsForLesson(val, (groups as List).map((g) => g['id']).toList());
              },
            ),
          ),
        Expanded(
          child: _students.isEmpty
              ? const AppEmptyWidget(
                  message: 'لا توجد طالبات في هذا الدرس',
                  icon: Icons.people_outline,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _students.length,
                  itemBuilder: (context, i) {
                    final student = _students[i];
                    final id = student['id'] as String;
                    final status = _attendanceMap[id] ?? AttendanceStatus.present;
                    return _StudentAttendanceRow(
                      name: student['name'] as String,
                      status: status,
                      onStatusChanged: (s) => setState(() => _attendanceMap[id] = s),
                    ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn().slideX(begin: 0.1);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStudentView() {
    if (_lessons.isEmpty) {
      return const AppEmptyWidget(
        message: AppStrings.noLessons,
        icon: Icons.calendar_today_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _lessons.length,
      itemBuilder: (context, i) {
        final record = _lessons[i];
        final status = AttendanceStatusExtension.fromString(record['status'] as String? ?? 'absent');
        return _AttendanceHistoryRow(
          title: record['title'] as String? ?? 'درس',
          date: record['date'] as String? ?? '',
          status: status,
        ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn().slideX(begin: 0.1);
      },
    );
  }
}

class _StudentAttendanceRow extends StatelessWidget {
  final String name;
  final AttendanceStatus status;
  final ValueChanged<AttendanceStatus> onStatusChanged;

  const _StudentAttendanceRow({
    required this.name,
    required this.status,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryVariant.withAlpha(40),
            child: Text(
              name.isNotEmpty ? name[0] : 'ط',
              style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
          ),
          _StatusChip(status: status, onChanged: onStatusChanged),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AttendanceStatus status;
  final ValueChanged<AttendanceStatus> onChanged;

  const _StatusChip({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AttendanceStatus>(
      initialValue: status,
      onSelected: onChanged,
      itemBuilder: (ctx) => AttendanceStatus.values.map((s) => PopupMenuItem(
            value: s,
            child: Row(
              children: [
                Icon(_statusIcon(s), color: _statusColor(s), size: 18),
                const SizedBox(width: 8),
                Text(s.label, style: AppTypography.bodyMedium),
              ],
            ),
          )).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _statusColor(status).withAlpha(30),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _statusColor(status).withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_statusIcon(status), color: _statusColor(status), size: 14),
            const SizedBox(width: 4),
            Text(
              status.label,
              style: AppTypography.labelSmall.copyWith(color: _statusColor(status)),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: _statusColor(status), size: 16),
          ],
        ),
      ),
    );
  }

  Color _statusColor(AttendanceStatus s) => switch (s) {
        AttendanceStatus.present => AppColors.present,
        AttendanceStatus.absent => AppColors.absent,
        AttendanceStatus.late => AppColors.late,
        AttendanceStatus.excused => AppColors.excused,
      };

  IconData _statusIcon(AttendanceStatus s) => switch (s) {
        AttendanceStatus.present => Icons.check_circle_outline,
        AttendanceStatus.absent => Icons.cancel_outlined,
        AttendanceStatus.late => Icons.access_time_outlined,
        AttendanceStatus.excused => Icons.info_outline,
      };
}

class _AttendanceHistoryRow extends StatelessWidget {
  final String title;
  final String date;
  final AttendanceStatus status;

  const _AttendanceHistoryRow({required this.title, required this.date, required this.status});

  Color get _color => switch (status) {
        AttendanceStatus.present => AppColors.present,
        AttendanceStatus.absent => AppColors.absent,
        AttendanceStatus.late => AppColors.late,
        AttendanceStatus.excused => AppColors.excused,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(right: BorderSide(color: _color, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                Text(date, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status.label, style: AppTypography.labelSmall.copyWith(color: _color)),
          ),
        ],
      ),
    );
  }
}
