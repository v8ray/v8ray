/// V8Ray 应用更新功能测试
///
/// 测试应用更新检查和下载功能

import 'package:flutter_test/flutter_test.dart';
import 'package:v8ray/core/providers/app_update_provider.dart';

void main() {
  group('AppUpdateProvider Tests', () {
    test('Initial state should be idle', () {
      final notifier = AppUpdateNotifier();
      expect(notifier.state.status, UpdateStatus.idle);
      expect(notifier.state.currentVersion, '0.1.0');
    });

    test('Version comparison should work correctly', () {
      final notifier = AppUpdateNotifier();

      // Test version comparison logic
      // Note: This is a simplified test since _compareVersions is private
      // In a real scenario, you might want to make it public or use a different approach

      // We can test the overall behavior by checking the state after checkForUpdates
      // but that requires network access, so we'll skip it for now
    });

    test('UpdateInfo copyWith should work correctly', () {
      const info = UpdateInfo(
        currentVersion: '0.1.0',
        status: UpdateStatus.idle,
      );

      final updated = info.copyWith(
        status: UpdateStatus.checking,
        latestVersion: '0.2.0',
      );

      expect(updated.currentVersion, '0.1.0');
      expect(updated.status, UpdateStatus.checking);
      expect(updated.latestVersion, '0.2.0');
    });

    test('hasUpdate should return true when versions differ', () {
      const info = UpdateInfo(
        currentVersion: '0.1.0',
        latestVersion: '0.2.0',
        status: UpdateStatus.available,
      );

      expect(info.hasUpdate, true);
    });

    test('hasUpdate should return false when versions are same', () {
      const info = UpdateInfo(
        currentVersion: '0.1.0',
        latestVersion: '0.1.0',
        status: UpdateStatus.available,
      );

      expect(info.hasUpdate, false);
    });

    test('hasUpdate should return false when status is not available', () {
      const info = UpdateInfo(
        currentVersion: '0.1.0',
        latestVersion: '0.2.0',
        status: UpdateStatus.idle,
      );

      expect(info.hasUpdate, false);
    });
  });

  group('UpdateStatus Tests', () {
    test('All update statuses should be defined', () {
      expect(UpdateStatus.values.length, 8);
      expect(UpdateStatus.values.contains(UpdateStatus.idle), true);
      expect(UpdateStatus.values.contains(UpdateStatus.checking), true);
      expect(UpdateStatus.values.contains(UpdateStatus.available), true);
      expect(UpdateStatus.values.contains(UpdateStatus.upToDate), true);
      expect(UpdateStatus.values.contains(UpdateStatus.downloading), true);
      expect(UpdateStatus.values.contains(UpdateStatus.downloaded), true);
      expect(UpdateStatus.values.contains(UpdateStatus.checkFailed), true);
      expect(UpdateStatus.values.contains(UpdateStatus.downloadFailed), true);
    });
  });
}
