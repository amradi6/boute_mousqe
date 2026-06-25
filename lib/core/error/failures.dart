import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure({required this.message});

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure({super.message = 'حدث خطأ في الخادم'});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'لا يوجد اتصال بالإنترنت'});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'خطأ في التخزين المحلي'});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}
