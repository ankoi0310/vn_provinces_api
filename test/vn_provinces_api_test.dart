import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:vn_provinces_api/vn_provinces_api.dart';

import 'vn_provinces_api_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late MockClient mockHttpClient;
  late VnProvincesClient client;
  late VnProvincesClient clientV1;

  setUp(() {
    mockHttpClient = MockClient();
    client = VnProvincesClient(httpClient: mockHttpClient);
    clientV1 = VnProvincesClient(version: ApiVersion.v1, httpClient: mockHttpClient);
  });

  tearDown(() {
    client.dispose();
    clientV1.dispose();
  });

  // ─── Helpers ───────────────────────────────────────────────────────────────

  http.Response mockResponse(Object body, {int statusCode = 200}) {
    return http.Response(json.encode(body), statusCode, headers: {'content-type': 'application/json; charset=utf-8'});
  }

  // ─── Province tests ────────────────────────────────────────────────────────

  group('getProvinces', () {
    test('trả về danh sách tỉnh thành', () async {
      when(mockHttpClient.get(any)).thenAnswer(
        (_) async => mockResponse([
          {
            'name': 'Thành phố Hà Nội',
            'code': 1,
            'codename': 'thanh_pho_ha_noi',
            'division_type': 'thành phố trung ương',
            'phone_code': 24,
            'districts': null,
          },
        ]),
      );

      final result = await client.getProvinces();

      expect(result, hasLength(1));
      expect(result.first.name, 'Thành phố Hà Nội');
      expect(result.first.code, 1);
      expect(result.first.isMunicipality, isTrue);
    });

    test('gọi đúng URL với depth', () async {
      when(mockHttpClient.get(any)).thenAnswer((_) async => mockResponse([]));
      await client.getProvinces(depth: 2);

      final captured = verify(mockHttpClient.get(captureAny)).captured.first as Uri;
      expect(captured.queryParameters['depth'], '2');
      expect(captured.path, contains('/api/v2/'));
    });

    test('v1 client gọi đúng base path', () async {
      when(mockHttpClient.get(any)).thenAnswer((_) async => mockResponse([]));
      await clientV1.getProvinces();

      final captured = verify(mockHttpClient.get(captureAny)).captured.first as Uri;
      expect(captured.path, contains('/api/v1/'));
    });
  });

  group('getProvince', () {
    test('trả về province với districts khi depth=2', () async {
      when(mockHttpClient.get(any)).thenAnswer(
        (_) async => mockResponse({
          'name': 'Thành phố Hà Nội',
          'code': 1,
          'codename': 'thanh_pho_ha_noi',
          'division_type': 'thành phố trung ương',
          'phone_code': 24,
          'wards': [
            {
              'name': 'Phường Ba Đình',
              'code': 4,
              'codename': 'phuong_ba_dinh',
              'division_type': 'phường',
              'province_code': 1,
            },
          ],
        }),
      );

      final result = await client.getProvince(1, depth: 2);

      expect(result.name, 'Thành phố Hà Nội');
      expect(result.wards, isNotNull);
      expect(result.wards!.first.name, 'Phường Ba Đình');
    });

    test('ném VnProvincesNotFoundException khi 404', () async {
      when(mockHttpClient.get(any)).thenAnswer((_) async => http.Response('Not found', 404));

      expect(() => client.getProvince(9999), throwsA(isA<VnProvincesNotFoundException>()));
    });

    test('ném VnProvincesHttpException khi 500', () async {
      when(mockHttpClient.get(any)).thenAnswer((_) async => http.Response('Server error', 500));

      expect(() => client.getProvince(1), throwsA(isA<VnProvincesHttpException>()));
    });
  });

  group('searchProvinces', () {
    test('trả về danh sách SearchResult', () async {
      when(mockHttpClient.get(any)).thenAnswer(
        (_) async => mockResponse([
          {
            'name': 'Thành phố Hà Nội',
            'code': 1,
            'score': 10,
            'matches': {
              'hà nội': [10, 16],
            },
          },
        ]),
      );

      final result = await client.searchProvinces('Hà Nội');

      expect(result, hasLength(1));
      expect(result.first.name, 'Thành phố Hà Nội');
      expect(result.first.score, 10);
    });
  });

  // ─── Ward tests ────────────────────────────────────────────────────────────

  group('getWard', () {
    test('trả về ward đúng thông tin', () async {
      when(mockHttpClient.get(any)).thenAnswer(
        (_) async => mockResponse({
          'name': 'Phường Bến Nghé',
          'code': 26743,
          'codename': 'phuong_ben_nghe',
          'division_type': 'phường',
          'province_code': 79,
        }),
      );

      final result = await client.getWard(26743);

      expect(result.name, 'Phường Bến Nghé');
      expect(result.divisionType, 'phường');
    });
  });

  // ─── Model tests ───────────────────────────────────────────────────────────

  group('Province model', () {
    test('isMunicipality đúng với thành phố trực thuộc TW', () {
      final p = const Province(
        name: 'Thành phố Hà Nội',
        code: 1,
        codename: 'thanh_pho_ha_noi',
        divisionType: 'thành phố trung ương',
      );
      expect(p.isMunicipality, isTrue);
    });

    test('isMunicipality false với tỉnh thường', () {
      final p = const Province(name: 'Tỉnh Hà Giang', code: 2, codename: 'tinh_ha_giang', divisionType: 'tỉnh');
      expect(p.isMunicipality, isFalse);
    });

    test('equality dựa trên code', () {
      final p1 = const Province(
        name: 'Thành phố Hà Nội',
        code: 1,
        codename: 'thanh_pho_ha_noi',
        divisionType: 'thành phố trung ương',
      );
      final p2 = const Province(name: 'Different name', code: 1, codename: 'other', divisionType: 'tỉnh');
      expect(p1, equals(p2));
    });
  });
}
