import 'package:equatable/equatable.dart';

abstract class TeacherState extends Equatable {
  const TeacherState();
  @override
  List<Object?> get props => [];
}

class TeacherInitial extends TeacherState {
  const TeacherInitial();
}

class TeacherLoading extends TeacherState {
  const TeacherLoading();
}

class TeacherLoaded extends TeacherState {
  final Map<String, dynamic> dashboard;
  const TeacherLoaded(this.dashboard);

  @override
  List<Object?> get props => [dashboard];
}

class TeacherError extends TeacherState {
  final String message;
  const TeacherError(this.message);

  @override
  List<Object?> get props => [message];
}
