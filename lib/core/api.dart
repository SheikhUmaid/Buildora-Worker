import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Thin wrapper over Dio: JSON in/out, bearer token, readable errors.
class ApiClient {
  ApiClient({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        _dio = Dio(BaseOptions(
          baseUrl: AppConfig.apiUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 120),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      if (_token != null) options.headers['Authorization'] = 'Bearer $_token';
      handler.next(options);
    }));
  }

  static const _tokenKey = 'auth_token';
  final Dio _dio;
  final FlutterSecureStorage _storage;
  String? _token;

  /// Called when the server rejects our token so the app can return to login.
  void Function()? onUnauthorized;

  bool get hasToken => _token != null;

  Future<String?> loadToken() async {
    try {
      _token = await _storage.read(key: _tokenKey);
    } catch (_) {
      _token = null;
    }
    return _token;
  }

  Future<void> setToken(String? token) async {
    _token = token;
    try {
      if (token == null) {
        await _storage.delete(key: _tokenKey);
      } else {
        await _storage.write(key: _tokenKey, value: token);
      }
    } catch (_) {
      // Secure storage can fail on some emulators; the session still works in memory.
    }
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: _clean(query)));

  Future<Map<String, dynamic>> post(String path, [Object? body]) => _send(() => _dio.post(path, data: body ?? {}));

  Future<Map<String, dynamic>> patch(String path, [Object? body]) => _send(() => _dio.patch(path, data: body ?? {}));

  Future<Map<String, dynamic>> delete(String path, [Object? body]) => _send(() => _dio.delete(path, data: body));

  /// Multipart upload. [files] maps a field name to local file paths.
  Future<Map<String, dynamic>> multipart(
    String method,
    String path, {
    Map<String, dynamic> fields = const {},
    Map<String, List<String>> files = const {},
    void Function(double progress)? onProgress,
  }) async {
    final form = FormData();
    fields.forEach((k, v) {
      if (v != null) form.fields.add(MapEntry(k, v.toString()));
    });
    for (final entry in files.entries) {
      for (final p in entry.value) {
        form.files.add(MapEntry(entry.key, await MultipartFile.fromFile(p, filename: p.split(Platform.pathSeparator).last)));
      }
    }
    return _send(() => _dio.request(
          path,
          data: form,
          options: Options(method: method),
          onSendProgress: onProgress == null ? null : (sent, total) => total > 0 ? onProgress(sent / total) : null,
        ));
  }

  Map<String, dynamic>? _clean(Map<String, dynamic>? q) {
    if (q == null) return null;
    final out = <String, dynamic>{};
    q.forEach((k, v) {
      if (v != null && v.toString().isNotEmpty) out[k] = v;
    });
    return out;
  }

  Future<Map<String, dynamic>> _send(Future<Response<dynamic>> Function() run) async {
    try {
      final res = await run();
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      return {'data': data};
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String message;
      if (data is Map && data['error'] is String) {
        message = data['error'] as String;
      } else if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        message = 'Cannot reach the server. Check your connection.';
      } else if (e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.sendTimeout) {
        message = 'The server took too long to respond.';
      } else {
        message = 'Something went wrong (${status ?? 'network'}).';
      }
      if (status == 401 && _token != null) onUnauthorized?.call();
      throw ApiException(message, statusCode: status);
    }
  }
}
