import 'package:equatable/equatable.dart';

enum EvaluationType { memorization, recitation, understanding, behavior }

extension EvaluationTypeExtension on EvaluationType {
  String get label => switch (this) {
        EvaluationType.memorization => 'حفظ',
        EvaluationType.recitation => 'تلاوة',
        EvaluationType.understanding => 'فهم',
        EvaluationType.behavior => 'سلوك',
      };

  String get value => switch (this) {
        EvaluationType.memorization => 'memorization',
        EvaluationType.recitation => 'recitation',
        EvaluationType.understanding => 'understanding',
        EvaluationType.behavior => 'behavior',
      };

  static EvaluationType fromString(String v) => switch (v) {
        'recitation' => EvaluationType.recitation,
        'understanding' => EvaluationType.understanding,
        'behavior' => EvaluationType.behavior,
        _ => EvaluationType.memorization,
      };
}

class EvaluationEntity extends Equatable {
  final String id;
  final String studentId;
  final String studentName;
  final String? studentAvatarUrl;
  final String teacherId;
  final String? teacherName;
  final EvaluationType type;
  final double score;
  final double maxScore;
  final String? notes;
  final DateTime evaluatedDate;

  const EvaluationEntity({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.studentAvatarUrl,
    required this.teacherId,
    this.teacherName,
    required this.type,
    required this.score,
    this.maxScore = 100,
    this.notes,
    required this.evaluatedDate,
  });

  double get percentage => (score / maxScore) * 100;

  String get grade {
    if (percentage >= 90) return 'ممتاز';
    if (percentage >= 80) return 'جيد جدًا';
    if (percentage >= 70) return 'جيد';
    if (percentage >= 60) return 'مقبول';
    return 'يحتاج تحسين';
  }

  @override
  List<Object?> get props => [id, studentId, type, score, evaluatedDate];
}
