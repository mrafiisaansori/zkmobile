import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Override per environment: flutter run --dart-define-from-file=.env
const baseUrl = String.fromEnvironment('API_BASE_URL',
    defaultValue: 'https://api.zonakasir.com/api');

class ApiException implements Exception {
  final String message;
  final int status;
  ApiException(this.message, [this.status = 0]);
  @override
  String toString() => message;
}

// Request gagal karena tidak sampai server (offline/putus) — beda dari
// ApiException yang berarti server SUDAH merespons (mis. validasi, stok habis).
bool isNetworkError(Object e) => e is! ApiException;

// User login — dipakai lintas fitur (Session.user.isPro dibaca di POS/admin
// buat feature-gating), jadi ditaruh berdampingan dengan Session, bukan di
// features/auth/, supaya core/ tidak balik bergantung ke features/.
class User {
  final int id;
  final String nama, username, role, plan;
  User.fromJson(Map<String, dynamic> j)
      : id = _i(j['id']),
        nama = '${j['nama'] ?? ''}',
        username = '${j['username'] ?? ''}',
        role = '${j['role'] ?? ''}',
        plan = '${(j['merchant'] ?? const {})['plan'] ?? 'FREE'}';

  // Member, open bill, split bill, dan pajak hanya untuk plan berbayar.
  bool get isPro => plan == 'PRO' || plan == 'BUSINESS';
}

int _i(dynamic v) => v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);

// Sesi disimpan di SharedPreferences (padanan localStorage 'pos-auth' di web).
class Session {
  static String? token;
  static User? user;

  static Future<void> restore() async {
    final sp = await SharedPreferences.getInstance();
    token = sp.getString('token');
    final u = sp.getString('user');
    if (u != null) user = User.fromJson(jsonDecode(u));
  }

  static Future<void> save(String t, Map<String, dynamic> u) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('token', t);
    await sp.setString('user', jsonEncode(u));
    token = t;
    user = User.fromJson(u);
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('token');
    await sp.remove('user');
    token = null;
    user = null;
  }

  static bool get isPro => user?.isPro ?? false;
}

Map<String, String> _headers() => {
      'Content-Type': 'application/json',
      if (Session.token != null) 'Authorization': 'Bearer ${Session.token}',
    };

// Backend selalu balas { success, message, data, meta }. Ambil `data`,
// dan ubah error jadi pesan siap tampil (padanan getErrorMessage di web).
dynamic _unwrap(http.Response res) {
  Map<String, dynamic> body = {};
  try {
    body = jsonDecode(res.body) as Map<String, dynamic>;
  } catch (_) {}
  if (res.statusCode >= 400) {
    final details = body['details'];
    final msg = '${body['message'] ?? 'Terjadi kesalahan tak terduga'}';
    throw ApiException(
      details is List && details.isNotEmpty ? '$msg: ${details.join(', ')}' : msg,
      res.statusCode,
    );
  }
  return body['data'];
}

Future<dynamic> apiGet(String path, [Map<String, dynamic>? query]) async {
  final q = (query ?? {})..removeWhere((_, v) => v == null);
  final uri = Uri.parse('$baseUrl$path')
      .replace(queryParameters: q.map((k, v) => MapEntry(k, '$v')));
  return _unwrap(await http.get(uri, headers: _headers()));
}

Future<dynamic> apiPost(String path, [Map<String, dynamic>? body]) async =>
    _unwrap(await http.post(Uri.parse('$baseUrl$path'),
        headers: _headers(), body: jsonEncode(body ?? {})));

Future<dynamic> apiPut(String path, Map<String, dynamic> body) async =>
    _unwrap(await http.put(Uri.parse('$baseUrl$path'),
        headers: _headers(), body: jsonEncode(body)));

Future<dynamic> apiDelete(String path) async =>
    _unwrap(await http.delete(Uri.parse('$baseUrl$path'), headers: _headers()));

// Tanpa contentType eksplisit, MultipartFile.fromPath default ke
// application/octet-stream — ditolak backend (whitelist jpg/png/webp di
// middlewares/upload.js) walau isi filenya gambar valid. Tebak dari
// ekstensi supaya backend terima.
MediaType _imageContentType(String filePath) {
  final ext = filePath.toLowerCase().split('.').last;
  return switch (ext) {
    'png' => MediaType('image', 'png'),
    'webp' => MediaType('image', 'webp'),
    _ => MediaType('image', 'jpeg'),
  };
}

// Multipart POST/PUT — dipakai form produk yang boleh sertakan foto. Field
// bernilai null dilewati (server anggap "tidak diubah" saat update).
Future<dynamic> _apiMultipart(
    String method, String path, Map<String, dynamic> fields, String? filePath, String fileField) async {
  final req = http.MultipartRequest(method, Uri.parse('$baseUrl$path'));
  req.headers.addAll(_headers()..remove('Content-Type'));
  fields.forEach((k, v) {
    if (v != null) req.fields[k] = '$v';
  });
  if (filePath != null) {
    req.files.add(await http.MultipartFile.fromPath(fileField, filePath,
        contentType: _imageContentType(filePath)));
  }
  final streamed = await req.send();
  return _unwrap(await http.Response.fromStream(streamed));
}

Future<dynamic> apiPostMultipart(String path, Map<String, dynamic> fields,
        {String? filePath, String fileField = 'foto'}) =>
    _apiMultipart('POST', path, fields, filePath, fileField);

Future<dynamic> apiPutMultipart(String path, Map<String, dynamic> fields,
        {String? filePath, String fileField = 'foto'}) =>
    _apiMultipart('PUT', path, fields, filePath, fileField);

// Helper dipakai repository per-fitur buat parse list respons.
List<T> apiList<T>(dynamic data, T Function(Map<String, dynamic>) f) =>
    ((data as List?) ?? []).map((e) => f(e as Map<String, dynamic>)).toList();

// Beberapa endpoint hanya tersedia di plan tertentu / belum diatur merchant.
// Kegagalannya tidak boleh menjatuhkan halaman POS.
Future<T?> apiOpsional<T>(Future<T> Function() f) async {
  try {
    return await f();
  } catch (_) {
    return null;
  }
}
