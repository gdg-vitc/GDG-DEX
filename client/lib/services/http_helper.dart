import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  final Uri? uri;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
    this.uri,
  });

  @override
  String toString() {
    final status = statusCode != null ? ' (Status $statusCode)' : '';
    final url = uri != null ? ' on $uri' : '';
    return 'ApiException$status$url: $message';
  }
}

class HttpHelper {
  static String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://sponge-romantic-pangolin.ngrok-free.app',
  );
  static String? token;
  static String? role;
  static String? userName;

  static Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  static Duration timeout = const Duration(seconds: 20);
  static bool enableLogging = kDebugMode;
  static http.Client client = http.Client();

  static void setToken(String value) {
    token = value;
  }

  static void clearToken() {
    token = null;
    role = null;
    userName = null;
  }

  static Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    String? token,
    Duration? customTimeout,
    T Function(dynamic json)? fromJson,
  }) {
    return request<T>(
      'GET',
      path,
      queryParams: queryParams,
      headers: headers,
      token: token,
      customTimeout: customTimeout,
      fromJson: fromJson,
    );
  }

  static Future<T> post<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    String? token,
    Duration? customTimeout,
    T Function(dynamic json)? fromJson,
  }) {
    return request<T>(
      'POST',
      path,
      body: body,
      queryParams: queryParams,
      headers: headers,
      token: token,
      customTimeout: customTimeout,
      fromJson: fromJson,
    );
  }

  static Future<T> put<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    String? token,
    Duration? customTimeout,
    T Function(dynamic json)? fromJson,
  }) {
    return request<T>(
      'PUT',
      path,
      body: body,
      queryParams: queryParams,
      headers: headers,
      token: token,
      customTimeout: customTimeout,
      fromJson: fromJson,
    );
  }

  static Future<T> patch<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    String? token,
    Duration? customTimeout,
    T Function(dynamic json)? fromJson,
  }) {
    return request<T>(
      'PATCH',
      path,
      body: body,
      queryParams: queryParams,
      headers: headers,
      token: token,
      customTimeout: customTimeout,
      fromJson: fromJson,
    );
  }

  static Future<T> delete<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    String? token,
    Duration? customTimeout,
    T Function(dynamic json)? fromJson,
  }) {
    return request<T>(
      'DELETE',
      path,
      body: body,
      queryParams: queryParams,
      headers: headers,
      token: token,
      customTimeout: customTimeout,
      fromJson: fromJson,
    );
  }

  static Future<T> request<T>(
    String method,
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    String? token,
    Duration? customTimeout,
    T Function(dynamic json)? fromJson,
  }) async {
    final uri = _buildUri(path, queryParams);
    final requestHeaders = _buildHeaders(headers, token: token);
    final encodedBody = _encodeBody(body, requestHeaders);

    _logRequest(method, uri, requestHeaders, body);

    final stopwatch = Stopwatch()..start();

    try {
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await client
              .get(uri, headers: requestHeaders)
              .timeout(customTimeout ?? timeout);
          break;
        case 'POST':
          response = await client
              .post(uri, headers: requestHeaders, body: encodedBody)
              .timeout(customTimeout ?? timeout);
          break;
        case 'PUT':
          response = await client
              .put(uri, headers: requestHeaders, body: encodedBody)
              .timeout(customTimeout ?? timeout);
          break;
        case 'PATCH':
          response = await client
              .patch(uri, headers: requestHeaders, body: encodedBody)
              .timeout(customTimeout ?? timeout);
          break;
        case 'DELETE':
          response = await client
              .delete(uri, headers: requestHeaders, body: encodedBody)
              .timeout(customTimeout ?? timeout);
          break;
        default:
          throw ApiException(message: 'Unsupported HTTP method: $method', uri: uri);
      }

      stopwatch.stop();
      _logResponse(method, uri, response, stopwatch.elapsed);

      return _handleResponse<T>(response, uri, fromJson);
    } on TimeoutException {
      stopwatch.stop();
      throw ApiException(
        message: 'Request timed out after ${(customTimeout ?? timeout).inSeconds}s',
        statusCode: 408,
        uri: uri,
      );
    } catch (e) {
      stopwatch.stop();
      if (e is ApiException) rethrow;

      final errorStr = e.toString().toLowerCase();
      if (kIsWeb && (e is http.ClientException || errorStr.contains('xmlhttprequest') || errorStr.contains('cors'))) {
        final currentBaseUrl = baseUrl;
        if (!currentBaseUrl.contains('localhost:8080') && !currentBaseUrl.contains('127.0.0.1:8080')) {
          try {
            baseUrl = 'http://localhost:8080';
            final fallbackResult = await request<T>(
              method,
              path,
              body: body,
              queryParams: queryParams,
              headers: headers,
              token: token,
              customTimeout: customTimeout,
              fromJson: fromJson,
            );
            return fallbackResult;
          } catch (_) {
            baseUrl = currentBaseUrl;
          }
        }

        throw ApiException(
          message: 'Connection blocked by browser (CORS). The FastAPI server needs CORSMiddleware enabled, or run Chrome with --disable-web-security.',
          statusCode: null,
          uri: uri,
        );
      }

      if (errorStr.contains('socketexception') ||
          errorStr.contains('connection refused') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('network is unreachable') ||
          e is http.ClientException) {
        throw ApiException(
          message: 'Unable to connect to server. Please check internet connection or backend status.',
          statusCode: null,
          uri: uri,
        );
      }

      throw ApiException(
        message: 'Network error: $e',
        statusCode: null,
        uri: uri,
      );
    }
  }

  static Uri _buildUri(String path, Map<String, dynamic>? queryParams) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      final base = Uri.parse(path);
      if (queryParams == null || queryParams.isEmpty) return base;
      final merged = Map<String, dynamic>.from(base.queryParameters)
        ..addAll(_cleanQueryParams(queryParams));
      return base.replace(queryParameters: _normalizeQueryParams(merged));
    }

    final trimmedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$trimmedBase$normalizedPath';
    final baseUri = Uri.parse(fullUrl);

    if (queryParams == null || queryParams.isEmpty) {
      return baseUri;
    }

    return baseUri.replace(
      queryParameters: _normalizeQueryParams(_cleanQueryParams(queryParams)),
    );
  }

  static Map<String, String> _buildHeaders(Map<String, String>? customHeaders, {String? token}) {
    final headers = Map<String, String>.from(defaultHeaders);

    final activeToken = token ?? HttpHelper.token;
    if (activeToken != null && activeToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $activeToken';
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  static dynamic _encodeBody(dynamic body, Map<String, String> headers) {
    if (body == null) return null;
    final contentType = headers['Content-Type'] ?? '';
    if (contentType.contains('application/json')) {
      if (body is Map || body is List) {
        return jsonEncode(body);
      }
    }
    return body;
  }

  static T _handleResponse<T>(
    http.Response response,
    Uri uri,
    T Function(dynamic json)? fromJson,
  ) {
    dynamic decodedData;
    if (response.body.isNotEmpty) {
      try {
        decodedData = jsonDecode(response.body);
      } catch (_) {
        decodedData = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (fromJson != null) {
        return fromJson(decodedData);
      }
      if (decodedData is T) {
        return decodedData;
      }
      if (T == dynamic || T == Object) {
        return decodedData as T;
      }
      if (response.body.isEmpty && null is T) {
        return null as T;
      }
      return decodedData as T;
    }

    String errorMessage = 'Request failed with status ${response.statusCode}';
    if (decodedData is Map<String, dynamic>) {
      if (decodedData['detail'] is Map) {
        final detailMap = decodedData['detail'] as Map;
        errorMessage = detailMap['message']?.toString() ??
            detailMap['msg']?.toString() ??
            detailMap['error']?.toString() ??
            detailMap.toString();
      } else if (decodedData['detail'] is List && (decodedData['detail'] as List).isNotEmpty) {
        final first = (decodedData['detail'] as List).first;
        if (first is Map && first['msg'] != null) {
          errorMessage = first['msg'].toString();
        } else {
          errorMessage = first.toString();
        }
      } else {
        errorMessage = decodedData['message']?.toString() ??
            decodedData['error']?.toString() ??
            decodedData['detail']?.toString() ??
            decodedData['msg']?.toString() ??
            errorMessage;
      }
    } else if (decodedData is String && decodedData.length < 150) {
      errorMessage = decodedData;
    }

    throw ApiException(
      message: errorMessage,
      statusCode: response.statusCode,
      data: decodedData,
      uri: uri,
    );
  }

  static Map<String, dynamic> _cleanQueryParams(Map<String, dynamic> params) {
    final cleaned = <String, dynamic>{};
    params.forEach((key, value) {
      if (value != null) cleaned[key] = value;
    });
    return cleaned;
  }

  static Map<String, String> _normalizeQueryParams(Map<String, dynamic> params) {
    return params.map((key, value) {
      if (value is Iterable) return MapEntry(key, value.join(','));
      return MapEntry(key, value.toString());
    });
  }

  static void _logRequest(String method, Uri uri, Map<String, String> headers, dynamic body) {
    if (!enableLogging) return;
    final authHeader = headers['Authorization'];
    final displayHeaders = Map<String, String>.from(headers);
    if (authHeader != null && authHeader.length > 20) {
      displayHeaders['Authorization'] = '${authHeader.substring(0, 15)}...';
    }

    debugPrint('🚀 [HTTP $method] $uri');
    if (body != null) debugPrint('   Body: $body');
  }

  static void _logResponse(String method, Uri uri, http.Response res, Duration duration) {
    if (!enableLogging) return;
    final isOk = res.statusCode >= 200 && res.statusCode < 300;
    final icon = isOk ? '✅' : '❌';
    debugPrint('$icon [HTTP ${res.statusCode}] $method $uri (${duration.inMilliseconds}ms)');
  }
}

Future<T> httpGet<T>(
  String path, {
  Map<String, dynamic>? queryParams,
  Map<String, String>? headers,
  String? token,
  Duration? timeout,
  T Function(dynamic json)? fromJson,
}) =>
    HttpHelper.get<T>(
      path,
      queryParams: queryParams,
      headers: headers,
      token: token,
      customTimeout: timeout,
      fromJson: fromJson,
    );

Future<T> httpPost<T>(
  String path, {
  dynamic body,
  Map<String, dynamic>? queryParams,
  Map<String, String>? headers,
  String? token,
  Duration? timeout,
  T Function(dynamic json)? fromJson,
}) =>
    HttpHelper.post<T>(
      path,
      body: body,
      queryParams: queryParams,
      headers: headers,
      token: token,
      customTimeout: timeout,
      fromJson: fromJson,
    );

Future<T> httpPut<T>(
  String path, {
  dynamic body,
  Map<String, dynamic>? queryParams,
  Map<String, String>? headers,
  String? token,
  Duration? timeout,
  T Function(dynamic json)? fromJson,
}) =>
    HttpHelper.put<T>(
      path,
      body: body,
      queryParams: queryParams,
      headers: headers,
      token: token,
      customTimeout: timeout,
      fromJson: fromJson,
    );

Future<T> httpPatch<T>(
  String path, {
  dynamic body,
  Map<String, dynamic>? queryParams,
  Map<String, String>? headers,
  String? token,
  Duration? timeout,
  T Function(dynamic json)? fromJson,
}) =>
    HttpHelper.patch<T>(
      path,
      body: body,
      queryParams: queryParams,
      headers: headers,
      token: token,
      customTimeout: timeout,
      fromJson: fromJson,
    );

Future<T> httpDelete<T>(
  String path, {
  dynamic body,
  Map<String, dynamic>? queryParams,
  Map<String, String>? headers,
  String? token,
  Duration? timeout,
  T Function(dynamic json)? fromJson,
}) =>
    HttpHelper.delete<T>(
      path,
      body: body,
      queryParams: queryParams,
      headers: headers,
      token: token,
      customTimeout: timeout,
      fromJson: fromJson,
    );
