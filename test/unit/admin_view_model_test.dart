import 'package:flutter_test/flutter_test.dart';
import 'package:cabros_bot_flutter/view_models/admin_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminViewModel', () {
    test('initializes with default tab and credentials', () {
      final vm = AdminViewModel();
      expect(vm.currentTab, AdminTab.overview);
      expect(vm.apiClient.baseUrl, AdminViewModel.defaultBaseUrl);
      expect(vm.apiClient.apiKey, isNull);
    });

    test('switches tabs and notifies listeners', () {
      final vm = AdminViewModel();
      var notifyCount = 0;
      vm.addListener(() => notifyCount++);

      vm.setTab(AdminTab.jobs);
      expect(vm.currentTab, AdminTab.jobs);
      expect(notifyCount, 1);

      // Same tab shouldn't notify
      vm.setTab(AdminTab.jobs);
      expect(notifyCount, 1);
    });

    test('manages job polling lifecycle', () {
      final vm = AdminViewModel();
      var tickCount = 0;

      vm.startJobPolling('job-123', () => tickCount++);
      expect(vm.activeJobId, 'job-123');
      expect(vm.jobPollPaused, isFalse);

      vm.toggleJobPolling();
      expect(vm.jobPollPaused, isTrue);

      vm.stopJobPolling();
      expect(vm.activeJobId, isNull);
      expect(vm.jobPollPaused, isFalse);
    });

    test('updates credentials and trims whitespace', () async {
      final vm = AdminViewModel();
      await vm.updateCredentials(
        newBaseUrl: '  https://custom-api.railway.app/  ',
        newApiKey: '  my-secret-key  ',
        newAuthToken: '  token-xyz  ',
      );

      expect(vm.apiClient.baseUrl, 'https://custom-api.railway.app/');
      expect(vm.apiClient.apiKey, 'my-secret-key');
      expect(vm.apiClient.authToken, 'token-xyz');
    });
  });
}
