class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server error']);
}

class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'Auth error']);
}

class OcrException implements Exception {
  final String message;
  const OcrException([this.message = 'OCR failed']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache error']);
}
