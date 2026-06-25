import 'package:equatable/equatable.dart';
import '../../domain/entities/student_dashboard_entity.dart';

abstract class StudentState extends Equatable {
  const StudentState();
  @override
  List<Object?> get props => [];
}

class StudentInitial extends StudentState {
  const StudentInitial();
}

class StudentLoading extends StudentState {
  const StudentLoading();
}

class StudentLoaded extends StudentState {
  final StudentDashboardEntity dashboard;
  const StudentLoaded(this.dashboard);

  @override
  List<Object?> get props => [dashboard];
}

class StudentError extends StudentState {
  final String message;
  const StudentError(this.message);

  @override
  List<Object?> get props => [message];
}
