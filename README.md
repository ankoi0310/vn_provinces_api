# vn_provinces_api

Flutter/Dart package để truy vấn dữ liệu địa chỉ tỉnh thành, quận huyện, phường xã Việt Nam qua API [provinces.open-api.vn](https://provinces.open-api.vn).

Hỗ trợ **API v2** (sau sáp nhập).

[![pub package](https://img.shields.io/pub/v/vn_provinces_api.svg)](https://pub.dev/packages/vn_provinces_api)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Tính năng

- ✅ Lấy danh sách tỉnh/thành phố, phường/xã
- ✅ Tìm kiếm theo tên (có dấu hoặc không dấu)
- ✅ Hỗ trợ `depth` để lấy dữ liệu lồng nhau (province → ward)
- ✅ Xử lý lỗi đầy đủ với các exception có nghĩa
- ✅ Hỗ trợ custom `http.Client` để dễ dàng mock trong test
- ✅ Null-safe, type-safe

---

## Cài đặt

```bash
dart pub add vn_provinces_api
```

---

## Sử dụng cơ bản

```dart
import 'package:vn_provinces_api/vn_provinces_api.dart';

void main() async {
  // Mặc định dùng API v2 (sau sáp nhập 07/2025)
  final client = VnProvincesClient();

  // Lấy tất cả tỉnh thành
  final provinces = await client.getProvinces();
  print(provinces.first.name); // Thành phố Hà Nội

  // Tìm kiếm tỉnh thành
  final results = await client.searchProvinces('Hồ Chí Minh');
  print(results.first.name); // Thành phố Hồ Chí Minh

  client.dispose(); // Đóng kết nối khi xong
}
```

---

## API Reference

### Khởi tạo

```dart
final client = VnProvincesClient();

// Tùy chỉnh timeout
final client = VnProvincesClient(timeout: Duration(seconds: 15));
```

### Tỉnh / Thành phố

| Phương thức | Mô tả |
|---|---|
| `getProvinces({depth})` | Lấy danh sách tất cả tỉnh thành |
| `getProvince(code, {depth})` | Lấy thông tin một tỉnh theo mã |
| `searchProvinces(q)` | Tìm kiếm tỉnh theo tên |

### Phường / Xã / Thị trấn

| Phương thức | Mô tả |
|---|---|
| `getWard(code)` | Lấy thông tin một phường/xã theo mã |
| `searchWards(q)` | Tìm kiếm phường/xã theo tên |

### Tham số `depth`

| `depth` | Dữ liệu trả về |
|---|---|
| `1` (mặc định) | Chỉ cấp hiện tại |
| `2` | Kèm cấp con (vd: province + wards) |

---

## Xử lý lỗi

```dart
try {
  final province = await client.getProvince(9999);
} on VnProvincesNotFoundException catch (e) {
  print('Không tìm thấy: ${e.message}');
} on VnProvincesNetworkException catch (e) {
  print('Lỗi mạng: ${e.message}');
} on VnProvincesHttpException catch (e) {
  print('Lỗi HTTP ${e.statusCode}: ${e.message}');
} on VnProvincesException catch (e) {
  print('Lỗi khác: ${e.message}');
}
```

### Danh sách exceptions

| Exception | Khi nào |
|---|---|
| `VnProvincesNotFoundException` | Mã không tồn tại (404) |
| `VnProvincesNetworkException` | Mất mạng, timeout |
| `VnProvincesHttpException` | Lỗi HTTP khác (4xx, 5xx) |
| `VnProvincesParseException` | JSON không hợp lệ |

---

## Ví dụ: Dropdown chọn địa chỉ 2 cấp

```dart
class AddressPicker extends StatefulWidget { ... }

class _AddressPickerState extends State<AddressPicker> {
  final client = VnProvincesClient();
  
  Province? selectedProvince;
  Ward? selectedWard;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dropdown tỉnh/thành
        FutureBuilder<List<Province>>(
          future: client.getProvinces(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            return DropdownButton<Province>(
              value: selectedProvince,
              items: snapshot.data!
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                  .toList(),
              onChanged: (p) async {
                setState(() => selectedProvince = p);
                final full = await client.getProvince(p!.code, depth: 2);
                // dùng full.wards cho dropdown tiếp theo
              },
            );
          },
        ),
        // ... dropdown phường/xã tương tự
      ],
    );
  }
}
```

---

## Testing

Package hỗ trợ inject `http.Client` để mock dễ dàng:

```dart
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

class MockClient extends Mock implements http.Client {}

final mockClient = MockClient();
final client = VnProvincesClient(httpClient: mockClient);

when(mockClient.get(any)).thenAnswer(
  (_) async => http.Response('[{"name":"Hà Nội","code":1,...}]', 200),
);

final provinces = await client.getProvinces();
expect(provinces.first.name, 'Hà Nội');
```

Chạy test:

```bash
flutter test
```

---

## Data source

API được cung cấp bởi [provinces.open-api.vn](https://provinces.open-api.vn), dựa trên thư viện [VietnamProvinces](https://pypi.org/project/vietnam-provinces/) của [Nguyễn Hồng Quân](https://quan.hoabinh.vn). Hosting được tài trợ bởi [OMZCloud](https://omzcloud.vn/).

Vui lòng không lạm dụng API công cộng.

---
