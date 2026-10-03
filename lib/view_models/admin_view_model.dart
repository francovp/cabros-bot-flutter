import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cabros_bot_flutter/data/models/admin_status.dart';
import 'package:cabros_bot_flutter/data/services/admin_service.dart';
import 'package:cabros_bot_flutter/data/services/api_client.dart';

enum AdminTab {
  overview,
  status,
  alerts,
  outcomes,
  presets,
  jobs,
  analysis,
  playground,
}

class AdminViewModel extends ChangeNotifier {
  static const String prefBaseUrlKey = 'cabros_admin_base_url';
  static const String prefApiKeyKey = 'cabros_admin_api_key';
  static const String defaultBaseUrl = 'https://openclaw.tail5e4271.ts.net';

  final ApiClient apiClient;
  late final AdminService adminService;

  AdminTab _currentTab = AdminTab.overview;
  AdminTab get currentTab => _currentTab;

  AdminStatus? _status;
  AdminStatus? get status => _status;

  bool _isStatusLoading = false;
  bool get isStatusLoading => _isStatusLoading;

  String? _statusError;
  String? get statusError => _statusError;

  DateTime? _lastChecked;
  DateTime? get lastChecked => _lastChecked;

  String? _activeJobId;
  String? get activeJobId => _activeJobId;
  Timer? _jobPollTimer;
  bool _jobPollPaused = false;
  bool get jobPollPaused => _jobPollPaused;

  AdminViewModel({ApiClient? client})
      : apiClient = client ?? ApiClient(baseUrl: defaultBaseUrl) {
    adminService = AdminService(client: apiClient);
  }

  Future<void> initPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(prefBaseUrlKey);
      final savedKey = prefs.getString(prefApiKeyKey);

      if (savedUrl != null && savedUrl.isNotEmpty) {
        apiClient.baseUrl = savedUrl;
      }
      if (savedKey != null && savedKey.isNotEmpty) {
        apiClient.apiKey = savedKey;
      }
      notifyListeners();
      await fetchStatus();
    } catch (_) {
      // Graceful fallback
      fetchStatus();
    }
  }

  void setTab(AdminTab tab) {
    if (_currentTab == tab) return;
    _currentTab = tab;
    stopJobPolling();
    notifyListeners();
  }

  Future<void> updateCredentials({
    required String newBaseUrl,
    required String newApiKey,
    String? newAuthToken,
  }) async {
    apiClient.baseUrl = newBaseUrl.trim().isEmpty ? defaultBaseUrl : newBaseUrl.trim();
    apiClient.apiKey = newApiKey.trim().isEmpty ? null : newApiKey.trim();
    apiClient.authToken = newAuthToken?.trim().isEmpty == true ? null : newAuthToken?.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefBaseUrlKey, apiClient.baseUrl);
      if (apiClient.apiKey != null) {
        await prefs.setString(prefApiKeyKey, apiClient.apiKey!);
      } else {
        await prefs.remove(prefApiKeyKey);
      }
    } catch (_) {}

    notifyListeners();
    await fetchStatus();
  }

  Future<void> clearApiKey() async {
    apiClient.apiKey = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefApiKeyKey);
    } catch (_) {}
    notifyListeners();
    await fetchStatus();
  }

  Future<void> fetchStatus() async {
    _isStatusLoading = true;
    _statusError = null;
    notifyListeners();

    try {
      _status = await adminService.getStatus();
      _lastChecked = DateTime.now();
      _statusError = null;
    } catch (e) {
      _statusError = e.toString();
    } finally {
      _isStatusLoading = false;
      notifyListeners();
    }
  }

  // Job Polling
  void startJobPolling(String jobId, VoidCallback onTick) {
    _activeJobId = jobId;
    _jobPollPaused = false;
    _jobPollTimer?.cancel();
    _jobPollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_jobPollPaused && _activeJobId == jobId) {
        onTick();
      }
    });
    notifyListeners();
  }

  void toggleJobPolling() {
    _jobPollPaused = !_jobPollPaused;
    notifyListeners();
  }

  void stopJobPolling() {
    _jobPollTimer?.cancel();
    _jobPollTimer = null;
    _activeJobId = null;
    _jobPollPaused = false;
  }

  @visibleForTesting
  void setStatusForTesting(AdminStatus newStatus) {
    _status = newStatus;
    _lastChecked = DateTime.now();
    _isStatusLoading = false;
    _statusError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _jobPollTimer?.cancel();
    apiClient.close();
    super.dispose();
  }
}
