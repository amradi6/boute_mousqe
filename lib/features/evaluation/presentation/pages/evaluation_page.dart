import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../domain/entities/evaluation_entity.dart';

class EvaluationPage extends StatefulWidget {
  final bool isTeacher;
  final String? studentId;

  const EvaluationPage({super.key, this.isTeacher = false, this.studentId});

  @override
  State<EvaluationPage> createState() => _EvaluationPageState();
}

class _EvaluationPageState extends State<EvaluationPage> {
  bool _loading = true;
  List<EvaluationEntity> _evaluations = [];
  List<Map<String, dynamic>> _students = [];
  String? _error;
  EvaluationType _typeFilter = EvaluationType.memorization;
  bool _showAll = true;

  @override
  void initState() {
    super.initState();
    _loadEvaluations();
    if (widget.isTeacher) _loadStudents();
  }

  Future<void> _loadEvaluations() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('المستخدم غير موجود');

      dynamic query;
      if (widget.isTeacher) {
        query = Supabase.instance.client
            .from('evaluations')
            .select('*, students(profiles(full_name))')
            .eq('teacher_id', userId);
      } else {
        final targetId = widget.studentId ?? userId;
        query = Supabase.instance.client
            .from('evaluations')
            .select('*, teachers(profiles(full_name))')
            .eq('student_id', targetId);
      }

      final data = await query.order('created_at', ascending: false).limit(50);

      final items = (data as List).map((e) {
        final teacherData = widget.isTeacher ? null : (e['teachers'] as Map?)?.cast<String, dynamic>();
        final studentData = widget.isTeacher ? (e['students'] as Map?)?.cast<String, dynamic>() : null;
        final teacherProfile = teacherData?['profiles'] as Map?;
        final studentProfile = studentData?['profiles'] as Map?;

        return EvaluationEntity(
          id: e['id'] as String,
          studentId: e['student_id'] as String,
          studentName: (studentProfile?['full_name'] as String?) ?? 'طالبة',
          teacherId: e['teacher_id'] as String,
          teacherName: (teacherProfile?['full_name'] as String?) ?? 'المعلمة',
          type: EvaluationTypeExtension.fromString(e['type'] as String? ?? 'memorization'),
          score: (e['score'] as num).toDouble(),
          maxScore: (e['max_score'] as num?)?.toDouble() ?? 100,
          notes: e['notes'] as String?,
          evaluatedDate: DateTime.parse(e['evaluated_date'] as String),
        );
      }).toList();

      setState(() {
        _evaluations = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadStudents() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final groups = await Supabase.instance.client
        .from('halaqah_groups')
        .select('id')
        .eq('teacher_id', userId);
    if ((groups as List).isEmpty) return;
    final groupIds = groups.map((g) => g['id']).toList();
    final students = await Supabase.instance.client
        .from('students')
        .select('id, profiles(full_name)')
        .inFilter('group_id', groupIds);
    setState(() {
      _students = (students as List).map((s) {
        final profile = (s['profiles'] as Map).cast<String, dynamic>();
        return {'id': s['id'] as String, 'name': profile['full_name'] as String? ?? 'طالبة'};
      }).toList();
    });
  }

  List<EvaluationEntity> get _filteredEvals =>
      _showAll ? _evaluations : _evaluations.where((e) => e.type == _typeFilter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.evaluation),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (widget.isTeacher)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              onPressed: () => _showAddDialog(),
            ),
        ],
      ),
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _loadEvaluations)
              : Column(
                  children: [
                    _buildFilterChips(),
                    Expanded(
                      child: _filteredEvals.isEmpty
                          ? const AppEmptyWidget(
                              message: AppStrings.noEvaluations,
                              icon: Icons.star_outline_rounded,
                            )
                          : RefreshIndicator(
                              onRefresh: _loadEvaluations,
                              color: AppColors.primary,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredEvals.length,
                                itemBuilder: (context, i) => _EvalCard(
                                  eval: _filteredEvals[i],
                                  showStudentName: widget.isTeacher,
                                ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn().slideY(begin: 0.2),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _FilterChip(
            label: 'الكل',
            selected: _showAll,
            onSelected: (_) => setState(() => _showAll = true),
          ),
          const SizedBox(width: 8),
          ...EvaluationType.values.map((type) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _FilterChip(
                  label: type.label,
                  selected: !_showAll && _typeFilter == type,
                  onSelected: (_) => setState(() {
                    _showAll = false;
                    _typeFilter = type;
                  }),
                ),
              )),
        ],
      ),
    );
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddEvaluationSheet(
        students: _students,
        onSaved: _loadEvaluations,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: AppTypography.labelMedium.copyWith(
        color: selected ? Colors.white : AppColors.textSecondary,
      ),
      backgroundColor: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      showCheckmark: false,
      side: BorderSide.none,
    );
  }
}

class _EvalCard extends StatelessWidget {
  final EvaluationEntity eval;
  final bool showStudentName;

  const _EvalCard({required this.eval, required this.showStudentName});

  Color get _gradeColor {
    if (eval.percentage >= 90) return AppColors.success;
    if (eval.percentage >= 70) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _gradeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon, color: _gradeColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showStudentName ? eval.studentName : eval.type.label,
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      showStudentName ? eval.type.label : 'المعلمة: ${eval.teacherName}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${eval.score.toInt()}/${eval.maxScore.toInt()}',
                    style: AppTypography.titleMedium.copyWith(
                      color: _gradeColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _gradeColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      eval.grade,
                      style: AppTypography.labelSmall.copyWith(color: _gradeColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (eval.notes != null && eval.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 8),
            Text(
              eval.notes!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${eval.evaluatedDate.day}/${eval.evaluatedDate.month}/${eval.evaluatedDate.year}',
            style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  IconData get _typeIcon => switch (eval.type) {
        EvaluationType.memorization => Icons.menu_book_rounded,
        EvaluationType.recitation => Icons.record_voice_over_outlined,
        EvaluationType.understanding => Icons.lightbulb_outline_rounded,
        EvaluationType.behavior => Icons.sentiment_satisfied_alt_outlined,
      };
}

class _AddEvaluationSheet extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final VoidCallback onSaved;

  const _AddEvaluationSheet({required this.students, required this.onSaved});

  @override
  State<_AddEvaluationSheet> createState() => _AddEvaluationSheetState();
}

class _AddEvaluationSheetState extends State<_AddEvaluationSheet> {
  final _scoreController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedStudentId;
  EvaluationType _selectedType = EvaluationType.memorization;
  bool _saving = false;

  @override
  void dispose() {
    _scoreController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedStudentId == null) return;
    final score = double.tryParse(_scoreController.text);
    if (score == null || score < 0 || score > 100) return;

    setState(() => _saving = true);
    try {
      await Supabase.instance.client.from('evaluations').insert({
        'student_id': _selectedStudentId,
        'teacher_id': Supabase.instance.client.auth.currentUser?.id,
        'type': _selectedType.value,
        'score': score,
        'max_score': 100,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'evaluated_date': DateTime.now().toIso8601String().substring(0, 10),
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة التقييم بنجاح'), backgroundColor: AppColors.success),
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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(AppStrings.addEvaluation, style: AppTypography.titleLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _selectedStudentId,
            decoration: const InputDecoration(labelText: 'الطالبة', prefixIcon: Icon(Icons.person_outline)),
            items: widget.students.map((s) => DropdownMenuItem(
                  value: s['id'] as String,
                  child: Text(s['name'] as String, style: AppTypography.bodyMedium),
                )).toList(),
            onChanged: (val) => setState(() => _selectedStudentId = val),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<EvaluationType>(
            initialValue: _selectedType,
            decoration: const InputDecoration(labelText: AppStrings.evaluationType, prefixIcon: Icon(Icons.category_outlined)),
            items: EvaluationType.values.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.label, style: AppTypography.bodyMedium),
                )).toList(),
            onChanged: (val) => setState(() => _selectedType = val ?? EvaluationType.memorization),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _scoreController,
            label: '${AppStrings.score} (0-100)',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.grade_outlined,
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _notesController,
            label: '${AppStrings.notes} (اختياري)',
            prefixIcon: Icons.notes_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: AppStrings.add,
            onPressed: _saving ? null : _save,
            isLoading: _saving,
            icon: Icons.check_rounded,
          ),
        ],
      ),
    );
  }
}
