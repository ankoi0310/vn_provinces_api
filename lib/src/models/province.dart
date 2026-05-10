import 'package:vn_provinces_api/src/enums.dart';
import 'package:vn_provinces_api/src/models/ward.dart';

/// Đơn vị hành chính cấp tỉnh/thành phố
class Province {
  /// Tên tỉnh/thành phố
  final String name;

  /// Mã số tỉnh/thành
  final int code;

  /// Tên định danh (slug), ví dụ: "thanh_pho_ha_noi"
  final String codename;

  /// Loại đơn vị: "tỉnh" hoặc "thành phố trung ương"
  final String divisionType;

  /// Mã vùng điện thoại
  final int? phoneCode;

  /// Danh sách phường (khi depth >= 2)
  final List<Ward>? wards;

  const Province({
    required this.name,
    required this.code,
    required this.codename,
    required this.divisionType,
    this.phoneCode,
    this.wards,
  });

  DivisionType get type => DivisionType.fromString(divisionType);

  /// Là thành phố trực thuộc trung ương?
  bool get isMunicipality => divisionType.toLowerCase().contains('thành phố trung ương');

  /// Creates a [Province] from a JSON map returned by the API.
  factory Province.fromJson(Map<String, dynamic> json) {
    final wardJson = json['wards'] as List<dynamic>?;
    return Province(
      name: json['name'] as String,
      code: json['code'] as int,
      codename: json['codename'] as String,
      divisionType: json['division_type'] as String,
      phoneCode: json['phone_code'] as int?,
      wards: wardJson?.map((d) => Ward.fromJson(d as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'codename': codename,
    'division_type': divisionType,
    if (phoneCode != null) 'phone_code': phoneCode,
    if (wards != null) 'wards': wards!.map((d) => d.toJson()).toList(),
  };

  @override
  String toString() => 'Province(code: $code, name: $name, type: $divisionType)';

  @override
  bool operator ==(Object other) => identical(this, other) || other is Province && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
