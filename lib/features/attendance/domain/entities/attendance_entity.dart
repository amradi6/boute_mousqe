import 'package:equatable/equatable.dart';

enum AttendanceStatus { present, absent, late, excused }

extension AttendanceStatusExtension on AttendanceStatus {
  String get label => switch (this) {
        AttendanceStatus.present => 'حاضرة',
        AttendanceStatus.absent => 'غائبة',
        AttendanceStatus.late => 'متأخرة',
        AttendanceStatus.excused => 'معذورة',
      };

  String get value => switch (this) {
        AttendanceStatus.present => 'present',
        AttendanceStatus.absent => 'absent',
        AttendanceStatus.late => 'late',
        AttendanceStatus.excused => 'excused',
      };

  static AttendanceStatus fromString(String v) => switch (v) {
        'present' => AttendanceStatus.present,
        'late' => AttendanceStatus.late,
        'excused' => AttendanceStatus.excused,
        _ => AttendanceStatus.absent,
      };
}

class AttendanceEntity extends Equatable {
  final String id;
  final String studentId;
  final String studentName;
  final String? studentAvatarUrl;
  final String lessonId;
  final AttendanceStatus status;
  final String? notes;
  final DateTime recordedAt;

  const AttendanceEntity({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.studentAvatarUrl,
    required this.lessonId,
    required this.status,
    this.notes,
    required this.recordedAt,
  });

  @override
  List<Object?> get props => [id, studentId, lessonId, status];
}
