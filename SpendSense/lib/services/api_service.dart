import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thrown whenever the API returns a non-2xx response.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  // TODO: replace with your laptop's LAN IP address.
  // Windows: run `ipconfig` and look for "IPv4 Address" under your WiFi adapter.
  // Mac/Linux: run `ifconfig` or `ip addr` and look for the WiFi interface (en0/wlan0).
  // Phone and laptop must be on the same WiFi network.
  static const String baseUrl = 'https://spendsense-1mdq.onrender.com';

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static Map<String, dynamic>? _currentUser;
  static Map<String, dynamic>? get currentUser => _currentUser;

  // ---------------- Token storage ----------------

  static Future<void> _saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  static Future<String?> getToken() => _storage.read(key: _tokenKey);

  static Future<void> clearToken() => _storage.delete(key: _tokenKey);

  static Future<bool> isLoggedIn() async => (await getToken()) != null;

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, String>> authHeaders() async => _authHeaders();

  static Map<String, dynamic> _decode(http.Response res) {
    if (res.body.isEmpty) return {};
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Map<String, dynamic> decode(http.Response res) => _decode(res);

  // ---------------- Auth ----------------

  /// Creates the account, then logs in immediately, since /auth/signup
  /// itself does not return a token.
  static Future<void> signUp({
    required String email,
    required String password,
    required List<String> categories,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'categories': categories,
      }),
    );

    final body = _decode(res);
    if (res.statusCode != 201) {
      throw ApiException(body['message'] ?? 'Signup failed', res.statusCode);
    }

    await login(email: email, password: password);
  }

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = _decode(res);
    if (res.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Login failed', res.statusCode);
    }

    await _saveToken(body['token'] as String);
    _currentUser = null;

    // Prime the user profile cache immediately so the profile page can render
    // without an extra failing request on first open.
    await getMe();
  }

  static Future<void> logout() async {
    _currentUser = null;
    await clearToken();
  }

  static Future<void> clearCurrentUser() async {
    _currentUser = null;
  }

  static Future<Map<String, dynamic>> getMe() async {
    if (_currentUser != null) {
      return _currentUser!;
    }

    final res = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: await _authHeaders(),
    );

    final body = _decode(res);
    if (res.statusCode != 200) {
      if (res.statusCode == 401) {
        await logout();
      }
      throw ApiException(
        body['message'] ?? 'Failed to fetch profile',
        res.statusCode,
      );
    }

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      _currentUser = Map<String, dynamic>.from(data);
    } else if (data is Map) {
      _currentUser = Map<String, dynamic>.from(data as Map);
    } else if (data is List && data.isNotEmpty && data.first is Map) {
      _currentUser = Map<String, dynamic>.from(data.first as Map);
    } else if (data is Map && data.containsKey('user')) {
      _currentUser = Map<String, dynamic>.from(data['user'] as Map);
    } else {
      throw ApiException('Invalid profile payload', res.statusCode);
    }

    return _currentUser!;
  }

  static Future<List<String>> updateCategories(List<String> categories) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/auth/categories'),
      headers: await _authHeaders(),
      body: jsonEncode({'categories': categories}),
    );

    final body = _decode(res);
    if (res.statusCode != 200) {
      throw ApiException(
        body['message'] ?? 'Failed to update categories',
        res.statusCode,
      );
    }
    final data = Map<String, dynamic>.from(body['data'] as Map);
    _currentUser = data;
    return List<String>.from(data['categories'] ?? []);
  }

  static Future<void> forgotPassword({required String email}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final body = _decode(res);
    if (res.statusCode != 200) {
      throw ApiException(
        body['message'] ?? 'Failed to send password reset request',
        res.statusCode,
      );
    }
  }

  // ---------------- Transactions ----------------

  static Future<List<Map<String, dynamic>>> getTransactions({
    String? category,
  }) async {
    final query = category != null ? '?category=$category' : '';
    final res = await http.get(
      Uri.parse('$baseUrl/transactions/expenditure$query'),
      headers: await _authHeaders(),
    );

    final body = _decode(res);
    if (res.statusCode != 200) {
      throw ApiException(
        body['message'] ?? 'Failed to fetch transactions',
        res.statusCode,
      );
    }
    return List<Map<String, dynamic>>.from(body['data'] as List);
  }

  static Future<Map<String, dynamic>> addTransaction({
    required String title,
    required String expenditureCategory, // 'income' | 'expense'
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/transactions/expenditure'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'title': title,
        'expenditureCategory': expenditureCategory,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'note': note,
      }),
    );

    final body = _decode(res);
    if (res.statusCode != 201) {
      throw ApiException(
        body['message'] ?? 'Failed to add transaction',
        res.statusCode,
      );
    }
    return Map<String, dynamic>.from(body['data'] as Map);
  }

  static Future<Map<String, dynamic>> editTransaction({
    required String id,
    required String title,
    required String expenditureCategory,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/transactions/expenditure/$id'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'title': title,
        'expenditureCategory': expenditureCategory,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'note': note,
      }),
    );

    final body = _decode(res);
    if (res.statusCode != 200) {
      throw ApiException(
        body['message'] ?? 'Failed to update transaction',
        res.statusCode,
      );
    }
    return Map<String, dynamic>.from(body['data'] as Map);
  }

  static Future<void> deleteTransaction(String id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/transactions/expenditure/$id'),
      headers: await _authHeaders(),
    );

    if (res.statusCode != 200) {
      final body = _decode(res);
      throw ApiException(
        body['message'] ?? 'Failed to delete transaction',
        res.statusCode,
      );
    }
  }
}
