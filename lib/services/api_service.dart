import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

/// Simple record for an API result.
class ApiResult {
  final bool ok;
  final dynamic data;
  final String? message;
  ApiResult({required this.ok, this.data, this.message});
}

/// Central API client for the AT Sol server.
///
/// Handles the PHP session cookie transparently so endpoints that require
/// authentication (users.php, change_password.php) work from mobile.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  String _server = AppConfig.defaultServerUrl;
  String? _cookie;
  Map<String, dynamic>? user;

  String get server => _server;
  Map<String, dynamic>? get currentUser => user;
  bool get isLoggedIn => user != null;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _server = p.getString('server') ?? AppConfig.defaultServerUrl;
    _cookie = p.getString('cookie');
    final u = p.getString('user');
    if (u != null) {
      try {
        user = jsonDecode(u) as Map<String, dynamic>;
      } catch (_) {}
    }
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    var base = _server.trim();
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Future<void> setServer(String url) async {
    var v = url.trim();
    if (v.isNotEmpty && !v.startsWith('http')) v = 'https://$v';
    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    _server = v;
    final p = await SharedPreferences.getInstance();
    await p.setString('server', v);
  }

  void _storeCookie(http.Response res) {
    final sc = res.headers['set-cookie'];
    if (sc == null) return;
    final match = RegExp(r'(PHPSESSID=[^;]+)').firstMatch(sc);
    if (match != null) _cookie = match.group(1);
  }

  Future<void> _persistSession() async {
    final p = await SharedPreferences.getInstance();
    if (_cookie != null) await p.setString('cookie', _cookie!);
    if (user != null) await p.setString('user', jsonEncode(user));
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_cookie != null) 'Cookie': _cookie!,
      };

  Future<ApiResult> _run(Future<http.Response> Function() fn) async {
    try {
      final res = await fn().timeout(const Duration(seconds: 30));
      _storeCookie(res);
      dynamic body;
      try {
        body = jsonDecode(utf8.decode(res.bodyBytes));
      } catch (_) {
        return ApiResult(ok: false, message: 'Invalid server response (HTTP ${res.statusCode})');
      }
      if (res.statusCode >= 400) {
        return ApiResult(ok: false, message: 'Server error (HTTP ${res.statusCode})');
      }
      final success = body is Map && body['success'] == true;
      return ApiResult(
        ok: success,
        data: success ? (body['data'] ?? body) : null,
        message: success ? null : ((body is Map ? body['message'] ?? body['error'] : null)?.toString() ?? 'Request failed'),
      );
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('TimeoutException')) msg = 'Connection timed out. Check your internet or server URL.';
      if (msg.contains('Failed host lookup') || msg.contains('SocketException')) {
        msg = 'Cannot reach server. Check your internet or server URL.';
      }
      return ApiResult(ok: false, message: msg);
    }
  }

  // ---------------- Auth ----------------

  Future<ApiResult> login(String username, String password) async {
    final r = await _run(() => http.post(_uri(AppConfig.epLogin),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password})));
    if (r.ok) {
      user = {
        'username': username,
        'full_name': (r.data as Map<String, dynamic>)['full_name'] ?? username,
        'role': (r.data as Map<String, dynamic>)['role'] ?? 'viewer',
      };
      await _persistSession();
    }
    return r;
  }

  Future<void> logout() async {
    try {
      await http.get(_uri(AppConfig.epLogout), headers: _headers).timeout(const Duration(seconds: 10));
    } catch (_) {}
    user = null;
    _cookie = null;
    final p = await SharedPreferences.getInstance();
    await p.remove('user');
    await p.remove('cookie');
  }

  bool get isAdmin => user?['role'] == 'admin';

  // ---------------- Generic calls ----------------

  Future<ApiResult> get(String path, [Map<String, String>? query]) =>
      _run(() => http.get(_uri(path, query), headers: _headers));

  Future<ApiResult> post(String path, Map<String, dynamic> body) =>
      _run(() => http.post(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<ApiResult> put(String path, Map<String, dynamic> body) =>
      _run(() => http.put(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<ApiResult> postQuery(String path, Map<String, String> query,
          [Map<String, dynamic>? body]) =>
      _run(() => http.post(_uri(path, query),
          headers: _headers, body: jsonEncode(body ?? {})));

  Future<ApiResult> del(String path, Map<String, String> query) =>
      _run(() => http.delete(_uri(path, query), headers: _headers));

  /// DELETE that carries a JSON body (used by definition endpoints).
  Future<ApiResult> delBody(String path, Map<String, dynamic> body) => _run(() async {
        final req = http.Request('DELETE', _uri(path))..headers.addAll(_headers)..body = jsonEncode(body);
        return req.send().then((s) => http.Response.fromStream(s));
      });

  Future<ApiResult> getList(String path) async {
    final r = await get(path);
    if (r.ok && r.data is List) return r;
    return ApiResult(ok: true, data: <dynamic>[]);
  }

  // ---------------- Dashboard ----------------

  Future<ApiResult> dashboardSummary() => get(AppConfig.epSummary);

  // ---------------- Sales ----------------

  Future<List<dynamic>> sales() => getList(AppConfig.epSalesList).then((r) => r.data as List<dynamic>);
  Future<List<dynamic>> saleReturns() => getList(AppConfig.epSaleReturnsList).then((r) => r.data as List<dynamic>);
  Future<ApiResult> saveSale(Map<String, dynamic> sale) => post(AppConfig.epSaleSave, sale);
  Future<ApiResult> deleteSale(int id) => post(AppConfig.epSaleDelete, {'id': id});
  Future<ApiResult> saveSaleReturn(Map<String, dynamic> sr) => post(AppConfig.epSaleReturnSave, sr);

  /// Next auto-generated sale invoice code, e.g. "00042".
  Future<String> nextSaleCode() async {
    final r = await get(AppConfig.epSaleNextCode);
    if (r.ok && r.data is Map) return '${(r.data as Map)['next_code'] ?? '1'}';
    return '1';
  }

  /// Next document code computed from [existing] codes (max + 1, padded to 5).
  static String nextCodeFrom(List<dynamic> existing) {
    int max = 0;
    for (final row in existing) {
      final v = int.tryParse('${row is Map ? row['code'] ?? '' : ''}') ?? 0;
      if (v > max) max = v;
    }
    return '${max + 1}'.padLeft(5, '0');
  }

  // ---------------- Purchases ----------------

  Future<List<dynamic>> purchases() => getList(AppConfig.epPurchasesList).then((r) => r.data as List<dynamic>);
  Future<List<dynamic>> purchaseOrders() => getList(AppConfig.epPoList).then((r) => r.data as List<dynamic>);
  Future<List<dynamic>> purchaseReturns() => getList(AppConfig.epPurReturnsList).then((r) => r.data as List<dynamic>);
  Future<ApiResult> savePurchase(Map<String, dynamic> p) => post(AppConfig.epPurchaseSave, p);
  Future<ApiResult> savePurchaseOrder(Map<String, dynamic> p) => post(AppConfig.epPoSave, p);
  Future<ApiResult> savePurchaseReturn(Map<String, dynamic> p) => post(AppConfig.epPurReturnSave, p);
  Future<ApiResult> deletePurchase(int id) => post(AppConfig.epPurchaseDelete, {'id': id});

  // ---------------- Transactions / Vouchers ----------------

  Future<List<dynamic>> transactions() => getList(AppConfig.epTransactions).then((r) => r.data as List<dynamic>);
  Future<ApiResult> saveTransaction(Map<String, dynamic> t) => post(AppConfig.epTransactionSave, t);
  Future<ApiResult> deleteTransaction(int id) => post(AppConfig.epTransactionDelete, {'id': id});

  // ---------------- Definitions (CRUD lists) ----------------

  Future<List<dynamic>> listAt(String path) => getList(path).then((r) => r.data as List<dynamic>);
}
