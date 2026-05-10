/// Base exception cho VnProvinces package
abstract class VnProvincesException implements Exception {
  final String message;
  const VnProvincesException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Lỗi kết nối mạng
class VnProvincesNetworkException extends VnProvincesException {
  const VnProvincesNetworkException(super.message);
}

/// Lỗi HTTP từ server (4xx, 5xx)
class VnProvincesHttpException extends VnProvincesException {
  final int statusCode;
  const VnProvincesHttpException(this.statusCode, super.message);

  @override
  String toString() => 'VnProvincesHttpException [$statusCode]: $message';
}

/// Không tìm thấy tài nguyên (404)
class VnProvincesNotFoundException extends VnProvincesException {
  const VnProvincesNotFoundException(super.message);
}

/// Lỗi parse JSON
class VnProvincesParseException extends VnProvincesException {
  const VnProvincesParseException(super.message);
}
