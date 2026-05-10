/// Phiên bản API
enum ApiVersion {
  /// V1: Dữ liệu trước sáp nhập tỉnh thành 07/2025
  v1,

  /// V2: Dữ liệu sau sáp nhập tỉnh thành 07/2025 (mặc định)
  v2,
}

/// Loại đơn vị hành chính
enum DivisionType {
  province,
  district,
  ward,
  unknown;

  /// Parses a Vietnamese division type string into a [DivisionType] enum value.
  static DivisionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'tỉnh':
      case 'thành phố trung ương':
        return DivisionType.province;
      case 'quận':
      case 'huyện':
      case 'thị xã':
      case 'thành phố':
        return DivisionType.district;
      case 'phường':
      case 'xã':
      case 'thị trấn':
        return DivisionType.ward;
      default:
        return DivisionType.unknown;
    }
  }
}

/// Độ sâu trả về dữ liệu (1 = chỉ province, 2 = + districts, 3 = + wards)
typedef Depth = int;
