import 'package:cabros_bot_flutter/data/models/admin_status.dart';
import 'package:cabros_bot_flutter/data/models/alert_model.dart';
import 'package:cabros_bot_flutter/data/models/job_model.dart';
import 'package:cabros_bot_flutter/data/models/openapi_spec.dart';
import 'package:cabros_bot_flutter/data/models/outcome_model.dart';
import 'package:cabros_bot_flutter/data/models/preset_model.dart';
import 'package:cabros_bot_flutter/data/services/api_client.dart';

class AdminService {
  final ApiClient client;
  Map<String, dynamic>? _cachedContract;
  List<ApiOperation>? _cachedOperations;

  AdminService({required this.client});

  Future<AdminStatus> getStatus() async {
    final res = await client.request(method: 'GET', path: '/api/status');
    if (!res.isOk || res.data == null) {
      throw Exception(res.error ?? 'Failed to load status (${res.statusCode}): ${res.body}');
    }
    return AdminStatus.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> loadContract() async {
    if (_cachedContract != null) return _cachedContract!;
    final res = await client.request(
      method: 'GET',
      path: '/openapi.json',
      customTimeoutMs: ApiClient.contractTimeoutMs,
    );
    if (!res.isOk || res.data == null) {
      throw Exception('Failed to load contract (${res.statusCode})');
    }
    _cachedContract = res.data as Map<String, dynamic>;
    _cachedOperations = ApiOperation.extractOperations(_cachedContract!);
    return _cachedContract!;
  }

  Future<List<ApiOperation>> getOperations() async {
    if (_cachedOperations != null) return _cachedOperations!;
    await loadContract();
    return _cachedOperations ?? [];
  }

  // Alerts
  Future<AlertListResponse> getAlerts({
    int limit = 50,
    String? before,
    String? source,
    String? enriched,
  }) async {
    final query = <String, dynamic>{
      'limit': limit,
      if (before != null && before.isNotEmpty) 'before': before,
      if (source != null && source.isNotEmpty) 'source': source,
      if (enriched != null && enriched.isNotEmpty) 'enriched': enriched,
    };
    final res = await client.request(method: 'GET', path: '/api/alerts', query: query);
    if (!res.isOk || res.data == null) {
      throw Exception('Failed to load alerts (${res.statusCode}): ${res.body}');
    }
    return AlertListResponse.fromJson(res.data);
  }

  Future<AlertItem> getAlertById(String alertId) async {
    final res = await client.request(method: 'GET', path: '/api/alerts/$alertId');
    if (!res.isOk || res.data == null) {
      throw Exception('Alert not found (${res.statusCode})');
    }
    final json = res.data is Map ? (res.data as Map).cast<String, dynamic>() : <String, dynamic>{};
    final alertData = json['alert'] is Map ? (json['alert'] as Map).cast<String, dynamic>() : json;
    return AlertItem.fromJson(alertData);
  }

  Future<AlertSummaryData> getAlertSummary({
    String? from,
    String? to,
    int limit = 500,
    String? source,
    String? enriched,
  }) async {
    final query = <String, dynamic>{
      'limit': limit,
      if (from != null && from.isNotEmpty) 'from': from,
      if (to != null && to.isNotEmpty) 'to': to,
      if (source != null && source.isNotEmpty) 'source': source,
      if (enriched != null && enriched.isNotEmpty) 'enriched': enriched,
    };
    final res = await client.request(method: 'GET', path: '/api/alerts/summary', query: query);
    if (!res.isOk || res.data == null) {
      throw Exception('Failed to load alert summary (${res.statusCode}): ${res.body}');
    }
    return AlertSummaryData.fromJson(res.data);
  }

  Future<ApiResponse> exportAlerts({
    String format = 'json',
    String? from,
    String? to,
    int limit = 500,
    String? source,
    String? enriched,
  }) async {
    final query = <String, dynamic>{
      'format': format,
      'limit': limit,
      if (from != null && from.isNotEmpty) 'from': from,
      if (to != null && to.isNotEmpty) 'to': to,
      if (source != null && source.isNotEmpty) 'source': source,
      if (enriched != null && enriched.isNotEmpty) 'enriched': enriched,
    };
    return client.request(method: 'GET', path: '/api/alerts/export', query: query);
  }

  Future<ApiResponse> replayAlert(String alertId, {String? idempotencyKey}) async {
    final key = idempotencyKey ?? 'admin-replay-${DateTime.now().millisecondsSinceEpoch}';
    return client.request(
      method: 'POST',
      path: '/api/alerts/$alertId/replay',
      body: {'idempotencyKey': key},
    );
  }

  // Outcomes
  Future<OutcomeListResponse> getOutcomes({
    int limit = 50,
    String? before,
    String? symbol,
    String? exchange,
    String? status,
    String? window,
    String? from,
    String? to,
  }) async {
    final query = <String, dynamic>{
      'limit': limit,
      if (before != null && before.isNotEmpty) 'before': before,
      if (symbol != null && symbol.isNotEmpty) 'symbol': symbol,
      if (exchange != null && exchange.isNotEmpty) 'exchange': exchange,
      if (status != null && status.isNotEmpty) 'status': status,
      if (window != null && window.isNotEmpty) 'window': window,
      if (from != null && from.isNotEmpty) 'from': from,
      if (to != null && to.isNotEmpty) 'to': to,
    };
    final res = await client.request(method: 'GET', path: '/api/outcomes', query: query);
    if (!res.isOk || res.data == null) {
      throw Exception('Failed to load outcomes (${res.statusCode}): ${res.body}');
    }
    return OutcomeListResponse.fromJson(res.data);
  }

  Future<OutcomeSummaryData> getOutcomesSummary({
    int limit = 50,
    String? symbol,
    String? exchange,
    String? status,
    String? window,
    String? from,
    String? to,
  }) async {
    final query = <String, dynamic>{
      'limit': limit,
      if (symbol != null && symbol.isNotEmpty) 'symbol': symbol,
      if (exchange != null && exchange.isNotEmpty) 'exchange': exchange,
      if (status != null && status.isNotEmpty) 'status': status,
      if (window != null && window.isNotEmpty) 'window': window,
      if (from != null && from.isNotEmpty) 'from': from,
      if (to != null && to.isNotEmpty) 'to': to,
    };
    final res = await client.request(method: 'GET', path: '/api/outcomes/summary', query: query);
    if (!res.isOk || res.data == null) {
      throw Exception('Failed to load outcomes summary (${res.statusCode}): ${res.body}');
    }
    return OutcomeSummaryData.fromJson(res.data);
  }

  // Scanner Presets
  Future<List<ScannerPreset>> getPresets() async {
    final res = await client.request(method: 'GET', path: '/api/scanner-presets');
    if (!res.isOk || res.data == null) {
      throw Exception('Failed to load presets (${res.statusCode}): ${res.body}');
    }
    final raw = res.data is Map
        ? ((res.data as Map)['presets'] as List<dynamic>? ?? [])
        : (res.data is List ? (res.data as List) : []);
    return raw
        .whereType<Map>()
        .map((item) => ScannerPreset.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<ApiResponse> createPreset(Map<String, dynamic> data) async {
    return client.request(method: 'POST', path: '/api/scanner-presets', body: data);
  }

  Future<ApiResponse> updatePreset(String id, Map<String, dynamic> data) async {
    return client.request(method: 'PUT', path: '/api/scanner-presets/$id', body: data);
  }

  Future<ApiResponse> deletePreset(String id) async {
    return client.request(method: 'DELETE', path: '/api/scanner-presets/$id');
  }

  Future<ApiResponse> runPreset(String id, {String? idempotencyKey}) async {
    final key = idempotencyKey ?? 'admin-preset-${DateTime.now().millisecondsSinceEpoch}';
    return client.request(
      method: 'POST',
      path: '/api/scanner-presets/$id/run',
      body: {'idempotencyKey': key},
    );
  }

  // Jobs
  Future<List<JobItem>> getJobs({int limit = 50, String? status, String? type}) async {
    final query = <String, dynamic>{
      'limit': limit,
      if (status != null && status.isNotEmpty) 'status': status,
      if (type != null && type.isNotEmpty) 'type': type,
    };
    final res = await client.request(method: 'GET', path: '/api/jobs', query: query);
    if (!res.isOk || res.data == null) {
      throw Exception('Failed to load jobs (${res.statusCode}): ${res.body}');
    }
    final rawJobs = res.data is Map
        ? ((res.data as Map)['jobs'] as List<dynamic>? ?? [])
        : (res.data is List ? (res.data as List) : []);
    return rawJobs
        .whereType<Map>()
        .map((j) => JobItem.fromJson(j.cast<String, dynamic>()))
        .toList();
  }

  Future<JobItem> getJobStatus(String jobId) async {
    final res = await client.request(method: 'GET', path: '/api/jobs/$jobId');
    if (!res.isOk || res.data == null) {
      throw Exception('Failed to load job status (${res.statusCode}): ${res.body}');
    }
    final json = res.data is Map ? (res.data as Map).cast<String, dynamic>() : <String, dynamic>{};
    final jobData = json['job'] is Map ? (json['job'] as Map).cast<String, dynamic>() : json;
    return JobItem.fromJson(jobData);
  }

  Future<ApiResponse> createJob(Map<String, dynamic> data, {String? idempotencyKey}) async {
    final key = idempotencyKey ?? 'admin-job-${DateTime.now().millisecondsSinceEpoch}';
    final payload = {...data, 'idempotencyKey': key};
    return client.request(method: 'POST', path: '/api/jobs/tradingview-analysis', body: payload);
  }

  Future<ApiResponse> cancelJob(String jobId) async {
    return client.request(method: 'POST', path: '/api/jobs/$jobId/cancel');
  }

  Future<ApiResponse> retryJob(String jobId, {String? idempotencyKey}) async {
    final key = idempotencyKey ?? 'admin-job-retry-${DateTime.now().millisecondsSinceEpoch}';
    return client.request(
      method: 'POST',
      path: '/api/jobs/$jobId/retry',
      body: {'idempotencyKey': key},
    );
  }

  Future<ApiResponse> retryFailedJob(String jobId, {String? idempotencyKey}) async {
    final key = idempotencyKey ?? 'admin-job-retryfailed-${DateTime.now().millisecondsSinceEpoch}';
    return client.request(
      method: 'POST',
      path: '/api/jobs/$jobId/retry-failed',
      body: {'idempotencyKey': key},
    );
  }

  // Quick Analysis Runners
  Future<ApiResponse> executeAnalysis(String path, dynamic body) async {
    return client.request(
      method: 'POST',
      path: path,
      body: body,
      customTimeoutMs: ApiClient.getTimeoutForPath(path),
    );
  }

  // Raw Playground runner
  Future<ApiResponse> executeRaw({
    required String method,
    required String path,
    Map<String, dynamic>? query,
    dynamic body,
  }) async {
    return client.request(
      method: method,
      path: path,
      query: query,
      body: body,
      customTimeoutMs: ApiClient.getTimeoutForPath(path),
    );
  }
}
