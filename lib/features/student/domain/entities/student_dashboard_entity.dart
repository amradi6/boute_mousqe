import 'package:equatable/equatable.dart';
import 'halaqah_entity.dart';
import 'lesson_entity.dart';
import '../../../evaluation/domain/entities/evaluation_entity.dart';

class StudentDashboardEntity extends Equatable {
  final HalaqahEntity? halaqah;
  final List<LessonEntity> recentLessons;
  final LessonEntity? nextLesson;
  final int totalLessons;
  final int attendedLessons;
  final EvaluationEntity? latestEvaluation;

  const StudentDashboardEntity({
    this.halaqah,
    required this.recentLessons,
    this.nextLesson,
    required this.totalLessons,
    required this.attendedLessons,
    this.latestEvaluation,
  });

  double get attendanceRate =>
      totalLessons == 0 ? 0 : (attendedLessons / totalLessons) * 100;

  @override
  List<Object?> get props => [halaqah, totalLessons, attendedLessons];
}
