import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiResponse {
  final int statusCode;
  final String body;
  final dynamic data;
  final int elapsedMs;
  final bool isOk;
  final String? error;

  ApiResponse({
    required this.statusCode,
    required this.body,
    this.data,
    required this.elapsedMs,
    required this.isOk,
    this.error,
  });
}

class ApiClient {
  static const int contractTimeoutMs = 8000;
  static const int apiRequestTimeoutMs = 30000;
  static const int volumeConfirmationTimeoutMs = 390000;
  static const int longRunningTimeoutMs = 990000;

  static const Set<String> longRunningPaths = {
    '/api/webhook/expanded-analysis-alert',
    '/api/webhook/market-scanner-alert',
    '/api/news-monitor',
    '/api/scanner-presets/{id}/run',
    '/api/webhook/alert',
    '/api/webhook/message',
    '/api/alerts/{alertId}/replay',
  };

  String baseUrl;
  String? apiKey;
  String? authToken;
  final http.Client _client;

  ApiClient({
    this.baseUrl = 'https://openclaw.tail5e4271.ts.net',
    this.apiKey,
    this.authToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  static int getTimeoutForPath(String path) {
    if (path == '/api/webhook/volume-confirmation' ||
        path == '/api/webhook/symbol-analysis') {
      return volumeConfirmationTimeoutMs;
    }
    if (longRunningPaths.contains(path)) {
      return longRunningTimeoutMs;
    }
    return apiRequestTimeoutMs;
  }

  static String redactSecret(String text, String? secret) {
    if (secret == null || secret.isEmpty) return text;
    var result = text.replaceAll(secret, '[REDACTED]');
    try {
      final jsonEscaped = jsonEncode(secret);
      final rawInner = jsonEscaped.substring(1, jsonEscaped.length - 1);
      if (rawInner.isNotEmpty && rawInner != secret) {
        result = result.replaceAll(rawInner, '[REDACTED]');
      }
    } catch (_) {}
    return result;
  }

  Uri buildUri(String path, [Map<String, dynamic>? query]) {
    final cleanBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$cleanBase$cleanPath';

    final filteredQuery = <String, String>{};
    if (query != null) {
      for (final entry in query.entries) {
        if (entry.value != null && entry.value.toString().isNotEmpty) {
          filteredQuery[entry.key] = entry.value.toString();
        }
      }
    }

    final parsed = Uri.parse(fullUrl);
    if (filteredQuery.isEmpty) return parsed;
    return parsed.replace(queryParameters: {
      ...parsed.queryParameters,
      ...filteredQuery,
    });
  }

  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, dynamic>? query,
    dynamic body,
    int? customTimeoutMs,
  }) async {
    final uri = buildUri(path, query);
    final headers = <String, String>{};

    if (apiKey != null && apiKey!.trim().isNotEmpty) {
      headers['x-api-key'] = apiKey!.trim();
    }
    if (authToken != null && authToken!.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${authToken!.trim()}';
    }

    String? encodedBody;
    if (body != null) {
      headers['Content-Type'] = 'application/json';
      encodedBody = body is String ? body : jsonEncode(body);
    }

    final timeout = Duration(
      milliseconds: customTimeoutMs ?? getTimeoutForPath(path),
    );
    final stopwatch = Stopwatch()..start();

    try {
      final request = http.Request(method.toUpperCase(), uri);
      request.headers.addAll(headers);
      if (encodedBody != null) {
        request.body = encodedBody;
      }

      final streamedResponse = await _client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);
      stopwatch.stop();

      dynamic parsedData;
      try {
        parsedData = jsonDecode(response.body);
      } catch (_) {
        parsedData = null;
      }

      return ApiResponse(
        statusCode: response.statusCode,
        body: response.body,
        data: parsedData,
        elapsedMs: stopwatch.elapsedMilliseconds,
        isOk: response.statusCode >= 200 && response.statusCode < 300,
      );
    } on TimeoutException {
      stopwatch.stop();
      return ApiResponse(
        statusCode: 408,
        body: 'Request timed out after ${timeout.inSeconds}s',
        elapsedMs: stopwatch.elapsedMilliseconds,
        isOk: false,
        error: 'Request timed out after ${timeout.inSeconds}s',
      );
    } catch (e) {
      stopwatch.stop();
      return ApiResponse(
        statusCode: 500,
        body: e.toString(),
        elapsedMs: stopwatch.elapsedMilliseconds,
        isOk: false,
        error: e.toString(),
      );
    }
  }

  void close() {
    _client.close();
  }
}
