import 'package:flutter/material.dart';
import 'package:vn_provinces_api/vn_provinces_api.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VN Provinces Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.red), useMaterial3: true),
      home: const AddressPickerPage(),
    );
  }
}

/// Demo: Chọn địa chỉ 3 cấp (Tỉnh → Huyện → Xã)
class AddressPickerPage extends StatefulWidget {
  const AddressPickerPage({super.key});

  @override
  State<AddressPickerPage> createState() => _AddressPickerPageState();
}

class _AddressPickerPageState extends State<AddressPickerPage> {
  final _client = VnProvincesClient(); // v2 — sau sáp nhập 07/2025

  List<Province> _provinces = [];
  List<Ward> _wards = [];

  Province? _selectedProvince;
  Ward? _selectedWard;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    setState(() => _loading = true);
    try {
      final provinces = await _client.getProvinces();
      setState(() {
        _provinces = provinces;
        _error = null;
      });
    } on VnProvincesException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _onProvinceChanged(Province? province) async {
    if (province == null) return;
    setState(() {
      _selectedProvince = province;
      _selectedWard = null;
      _wards = [];
      _loading = true;
    });
    try {
      final full = await _client.getProvince(province.code, depth: 2);
      setState(() {
        _wards = full.wards ?? [];
        _error = null;
      });
    } on VnProvincesException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  String get _fullAddress {
    final parts = [
      if (_selectedWard != null) _selectedWard!.name,
      if (_selectedProvince != null) _selectedProvince!.name,
    ];
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn địa chỉ Việt Nam'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 12),

            // Tỉnh/Thành phố
            _buildDropdown<Province>(
              label: 'Tỉnh / Thành phố',
              value: _selectedProvince,
              items: _provinces,
              itemLabel: (p) => p.name,
              onChanged: _onProvinceChanged,
            ),

            const SizedBox(height: 16),

            // Phường/Xã
            _buildDropdown<Ward>(
              label: 'Phường / Xã / Thị trấn',
              value: _selectedWard,
              items: _wards,
              itemLabel: (w) => w.name,
              onChanged: (ward) => setState(() => _selectedWard = ward),
              enabled: _selectedProvince != null,
            ),

            const SizedBox(height: 32),

            if (_fullAddress.isNotEmpty) ...[
              const Text('Địa chỉ đã chọn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_fullAddress, style: const TextStyle(fontSize: 15)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), enabled: enabled),
      initialValue: value,
      hint: Text('Chọn $label'),
      isExpanded: true,
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
    );
  }
}
