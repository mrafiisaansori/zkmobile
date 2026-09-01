int i(dynamic v) => v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
String? s(dynamic v) {
  final str = v?.toString().trim();
  return (str == null || str.isEmpty) ? null : str;
}
