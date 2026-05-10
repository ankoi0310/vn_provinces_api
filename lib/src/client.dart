import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'enums.dart';
import 'exceptions.dart';
import 'models/province.dart';
import 'models/search_result.dart';
import 'models/ward.dart';

/// Client chính để gọi API provinces.open-api.vn
///
/// Hỗ trợ cả v1 (trước sáp nhập 07/2025) và v2 (sau sáp nhập 07/2025).
///
/// ```dart
/// // Khởi tạo với v2 (mặc định, sau sáp nhập)
/// final client = VnProvincesClient();
///
/// // Khởi tạo với v1 (trước sáp nhập)
/// final clientV1 = VnProvincesClient(version: ApiVersion.v1);
///
/// // Lấy tất cả tỉnh thành
/// final provinces = await client.getProvinces();
///
/// // Lấy tỉnh kèm quận huyện
/// final hn = await client.getProvince(1, depth: 2);
///
/// // Lấy tỉnh kèm quận huyện và phường xã (chú ý: tốn tài nguyên server)
/// final full = await client.getProvince(1, depth: 3);
///
/// // Tìm kiếm
/// final found = await client.searchProvinces('Hà Nội');
/// ```
class VnProvincesClient {
  static const String _baseUrl = 'https://provinces.open-api.vn';

  final ApiVersion version;
  final http.Client _httpClient;
  final Duration timeout;

  /// [version]: Phiên bản API (mặc định v2 — sau sáp nhập 07/2025)
  /// [httpClient]: HTTP client tùy chỉnh (hữu ích cho testing)
  /// [timeout]: Thời gian chờ tối đa mỗi request (mặc định 10 giây)
  VnProvincesClient({this.version = ApiVersion.v2, http.Client? httpClient, this.timeout = const Duration(seconds: 10)})
    : _httpClient = httpClient ?? http.Client();

  String get _versionPath => switch (version) {
    ApiVersion.v1 => 'v1',
    ApiVersion.v2 => 'v2',
  };

  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    return Uri.parse('$_baseUrl/api/$_versionPath$path').replace(queryParameters: queryParams);
  }

  Future<dynamic> _get(Uri uri) async {
    try {
      final response = await _httpClient.get(uri).timeout(timeout);
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw VnProvincesNetworkException('Lỗi kết nối mạng: ${e.message}');
    } on TimeoutException {
      throw const VnProvincesNetworkException('Request timeout. Vui lòng thử lại.');
    }
  }

  dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        try {
          return json.decode(utf8.decode(response.bodyBytes));
        } catch (e) {
          throw VnProvincesParseException('Lỗi parse JSON: $e');
        }
      case 404:
        throw const VnProvincesNotFoundException('Không tìm thấy dữ liệu.');
      default:
        throw VnProvincesHttpException(response.statusCode, 'Lỗi server: ${response.statusCode}');
    }
  }

  // ─────────────────────────────────────────────────────────
  // PROVINCES — Tỉnh/Thành phố
  // ─────────────────────────────────────────────────────────

  /// Lấy danh sách tất cả tỉnh thành.
  ///
  /// [depth]: 1 = chỉ tỉnh, 2 = kèm quận/huyện, 3 = kèm cả phường/xã.
  /// ⚠️ Hạn chế dùng depth=3 để tránh tải nặng cho server.
  Future<List<Province>> getProvinces({int depth = 1}) async {
    final uri = _buildUri('/', {'depth': '$depth'});
    final data = await _get(uri) as List<dynamic>;
    return data.map((p) => Province.fromJson(p as Map<String, dynamic>)).toList();
  }

  /// Lấy thông tin chi tiết một tỉnh theo [code].
  ///
  /// [depth]: 1 = chỉ tỉnh, 2 = kèm quận/huyện, 3 = kèm cả phường/xã.
  Future<Province> getProvince(int code, {int depth = 1}) async {
    final uri = _buildUri('/p/$code', {'depth': '$depth'});
    final data = await _get(uri) as Map<String, dynamic>;
    return Province.fromJson(data);
  }

  /// Tìm kiếm tỉnh/thành phố theo từ khóa [q].
  Future<List<SearchResult>> searchProvinces(String q) async {
    final uri = _buildUri('/p/search/', {'q': q});
    final data = await _get(uri) as List<dynamic>;
    return data.map((p) => SearchResult.fromJson(p as Map<String, dynamic>)).toList();
  }

  // ─────────────────────────────────────────────────────────
  // WARDS — Phường/Xã/Thị trấn
  // ─────────────────────────────────────────────────────────

  /// Lấy thông tin chi tiết một phường/xã theo [code].
  Future<Ward> getWard(int code) async {
    final uri = _buildUri('/w/$code');
    final data = await _get(uri) as Map<String, dynamic>;
    return Ward.fromJson(data);
  }

  /// Tìm kiếm phường/xã theo từ khóa [q].
  Future<List<SearchResult>> searchWards(String q) async {
    final uri = _buildUri('/w/search/', {'q': q});
    final data = await _get(uri) as List<dynamic>;
    return data.map((w) => SearchResult.fromJson(w as Map<String, dynamic>)).toList();
  }

  /// Đóng HTTP client khi không còn sử dụng.
  void dispose() => _httpClient.close();
}
