class ServerException implements Exception {
  final String message;
  const ServerException({this.message = 'حدث خطأ في الخادم'});
}

class AppAuthException implements Exception {
  final String message;
  const AppAuthException({required this.message});
}

class NetworkException implements Exception {
  final String message;
  const NetworkException({this.message = 'لا يوجد اتصال بالإنترنت'});
}

class CacheException implements Exception {
  final String message;
  const CacheException({this.message = 'خطأ في التخزين المحلي'});
}

class ValidationException implements Exception {
  final String message;
  const ValidationException({required this.message});
}
