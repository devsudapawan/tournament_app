abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

class OcrFailure extends Failure {
  const OcrFailure([super.message = 'Could not read image']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local cache error']);
}
