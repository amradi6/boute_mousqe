import 'package:equatable/equatable.dart';

class LessonEntity extends Equatable {
  final String id;
  final String groupId;
  final String title;
  final String? description;
  final DateTime lessonDate;
  final int durationMinutes;
  final String status; // scheduled, completed, cancelled

  const LessonEntity({
    required this.id,
    required this.groupId,
    required this.title,
    this.description,
    required this.lessonDate,
    this.durationMinutes = 60,
    required this.status,
  });

  bool get isCompleted => status == 'completed';
  bool get isUpcoming => status == 'scheduled' && lessonDate.isAfter(DateTime.now());

  @override
  List<Object?> get props => [id, groupId, title, lessonDate, status];
}
