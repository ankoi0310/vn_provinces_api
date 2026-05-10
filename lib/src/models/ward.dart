import 'package:vn_provinces_api/src/enums.dart';

/// Đơn vị hành chính cấp phường/xã/thị trấn
class Ward {
  /// Tên phường/xã
  final String name;

  /// Mã số
  final int code;

  /// Tên định danh (slug), ví dụ: "phuong_ben_nghe"
  final String codename;

  /// Loại đơn vị: "phường", "xã", "thị trấn"
  final String divisionType;

  /// Mã quận/huyện cha
  final int? districtCode;

  /// Mã tỉnh/thành cha (v2)
  final int? provinceCode;

  const Ward({
    required this.name,
    required this.code,
    required this.codename,
    required this.divisionType,
    this.districtCode,
    this.provinceCode,
  });

  DivisionType get type => DivisionType.fromString(divisionType);

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(
      name: json['name'] as String,
      code: json['code'] as int,
      codename: json['codename'] as String,
      divisionType: json['division_type'] as String,
      districtCode: json['district_code'] as int?,
      provinceCode: json['province_code'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'codename': codename,
    'division_type': divisionType,
    if (districtCode != null) 'district_code': districtCode,
    if (provinceCode != null) 'province_code': provinceCode,
  };

  @override
  String toString() => 'Ward(code: $code, name: $name, type: $divisionType)';

  @override
  bool operator ==(Object other) => identical(this, other) || other is Ward && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
