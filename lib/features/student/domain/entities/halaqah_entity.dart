import 'package:equatable/equatable.dart';

class HalaqahEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? teacherName;
  final String? teacherAvatarUrl;
  final int studentCount;
  final String? location;
  final String? scheduleDay;
  final String? scheduleTime;

  const HalaqahEntity({
    required this.id,
    required this.name,
    this.description,
    this.teacherName,
    this.teacherAvatarUrl,
    this.studentCount = 0,
    this.location,
    this.scheduleDay,
    this.scheduleTime,
  });

  @override
  List<Object?> get props => [id, name, teacherName];
}
