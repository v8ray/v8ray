import 'package:flutter_test/flutter_test.dart';
import 'package:v8ray/core/providers/xray_core_update_provider.dart';

void main() {
  group('XrayCoreUpdateInfo', () {
    test('初始状态应该正确', () {
      const info = XrayCoreUpdateInfo(
        currentVersion: '1.0.0',
        status: XrayCoreUpdateStatus.idle,
      );

      expect(info.currentVersion, '1.0.0');
      expect(info.status, XrayCoreUpdateStatus.idle);
      expect(info.latestVersion, null);
      expect(info.downloadProgress, 0.0);
      expect(info.errorMessage, null);
      expect(info.hasUpdate, false);
    });

    test('hasUpdate 应该在有新版本时返回 true', () {
      const info = XrayCoreUpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.1.0',
        status: XrayCoreUpdateStatus.available,
      );

      expect(info.hasUpdate, true);
    });

    test('hasUpdate 应该在版本相同时返回 false', () {
      const info = XrayCoreUpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        status: XrayCoreUpdateStatus.available,
      );

      expect(info.hasUpdate, false);
    });

    test('hasUpdate 应该在当前版本为 "not installed" 时返回 false', () {
      const info = XrayCoreUpdateInfo(
        currentVersion: 'not installed',
        latestVersion: '1.0.0',
        status: XrayCoreUpdateStatus.available,
      );

      expect(info.hasUpdate, false);
    });

    test('hasUpdate 应该在当前版本为 "unknown" 时返回 false', () {
      const info = XrayCoreUpdateInfo(
        currentVersion: 'unknown',
        latestVersion: '1.0.0',
        status: XrayCoreUpdateStatus.available,
      );

      expect(info.hasUpdate, false);
    });

    test('hasUpdate 应该在状态不是 available 时返回 false', () {
      const info = XrayCoreUpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.1.0',
        status: XrayCoreUpdateStatus.idle,
      );

      expect(info.hasUpdate, false);
    });

    test('copyWith 应该正确复制和修改属性', () {
      const original = XrayCoreUpdateInfo(
        currentVersion: '1.0.0',
        status: XrayCoreUpdateStatus.idle,
      );

      final updated = original.copyWith(
        latestVersion: '1.1.0',
        status: XrayCoreUpdateStatus.available,
        downloadProgress: 0.5,
      );

      expect(updated.currentVersion, '1.0.0');
      expect(updated.latestVersion, '1.1.0');
      expect(updated.status, XrayCoreUpdateStatus.available);
      expect(updated.downloadProgress, 0.5);
    });

    test('copyWith 应该能清除 errorMessage', () {
      const original = XrayCoreUpdateInfo(
        currentVersion: '1.0.0',
        status: XrayCoreUpdateStatus.checkFailed,
        errorMessage: 'Some error',
      );

      final updated = original.copyWith(
        status: XrayCoreUpdateStatus.checking,
        errorMessage: null,
      );

      expect(updated.errorMessage, null);
    });
  });

  group('XrayCoreUpdateStatus', () {
    test('应该包含所有必要的状态', () {
      expect(XrayCoreUpdateStatus.values, contains(XrayCoreUpdateStatus.idle));
      expect(
        XrayCoreUpdateStatus.values,
        contains(XrayCoreUpdateStatus.checking),
      );
      expect(
        XrayCoreUpdateStatus.values,
        contains(XrayCoreUpdateStatus.available),
      );
      expect(
        XrayCoreUpdateStatus.values,
        contains(XrayCoreUpdateStatus.upToDate),
      );
      expect(
        XrayCoreUpdateStatus.values,
        contains(XrayCoreUpdateStatus.downloading),
      );
      expect(
        XrayCoreUpdateStatus.values,
        contains(XrayCoreUpdateStatus.downloaded),
      );
      expect(
        XrayCoreUpdateStatus.values,
        contains(XrayCoreUpdateStatus.checkFailed),
      );
      expect(
        XrayCoreUpdateStatus.values,
        contains(XrayCoreUpdateStatus.downloadFailed),
      );
      expect(
        XrayCoreUpdateStatus.values,
        contains(XrayCoreUpdateStatus.installFailed),
      );
    });
  });

  group('XrayCoreUpdateNotifier', () {
    test('初始状态应该正确', () {
      final notifier = XrayCoreUpdateNotifier();

      expect(notifier.state.currentVersion, 'unknown');
      expect(notifier.state.status, XrayCoreUpdateStatus.idle);
      expect(notifier.state.latestVersion, null);
      expect(notifier.state.downloadProgress, 0.0);
      expect(notifier.state.errorMessage, null);
    });

    test('reset 应该重置状态但保留当前版本', () {
      final notifier = XrayCoreUpdateNotifier();

      // 模拟一些状态变化
      notifier.state = notifier.state.copyWith(
        currentVersion: '1.0.0',
        latestVersion: '1.1.0',
        status: XrayCoreUpdateStatus.available,
        downloadProgress: 0.5,
        errorMessage: 'Some error',
      );

      // 重置
      notifier.reset();

      expect(notifier.state.currentVersion, '1.0.0');
      expect(notifier.state.status, XrayCoreUpdateStatus.idle);
      expect(notifier.state.latestVersion, null);
      expect(notifier.state.downloadProgress, 0.0);
      expect(notifier.state.errorMessage, null);
    });
  });
}
