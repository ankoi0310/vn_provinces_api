/// Kết quả tìm kiếm tỉnh/quận/phường
class SearchResult {
  /// Tên đơn vị
  final String name;

  /// Mã số
  final int code;

  /// Điểm khớp (dùng để sắp xếp kết quả)
  final int? score;

  /// Vị trí các ký tự khớp trong tên
  final Map<String, List<int>>? matches;

  const SearchResult({
    required this.name,
    required this.code,
    this.score,
    this.matches,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final matchesRaw = json['matches'] as Map<String, dynamic>?;
    return SearchResult(
      name: json['name'] as String,
      code: json['code'] as int,
      score: json['score'] as int?,
      matches: matchesRaw?.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>).cast<int>(),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        if (score != null) 'score': score,
        if (matches != null) 'matches': matches,
      };

  @override
  String toString() => 'SearchResult(code: $code, name: $name, score: $score)';
}
