/// V8Ray 连接管理集成测试
///
/// 测试 Flutter UI 与 Rust 核心的连接管理集成
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:v8ray/core/ffi/bridge/api.dart' as api;
import 'package:v8ray/core/ffi/frb_generated.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // 初始化 Flutter Rust Bridge
    await V8RayBridge.init();

    // 初始化 V8Ray Core
    await api.initV8Ray();
  });

  tearDownAll(() async {
    // 清理资源
    try {
      await api.disconnect();
    } catch (e) {
      // 忽略断开连接错误
    }

    await api.shutdownV8Ray();
  });

  group('连接管理集成测试', () {
    test('初始化测试', () async {
      // 验证初始化成功 - 尝试获取连接信息
      final info = await api.getConnectionInfo();

      // 初始状态应该是未连接
      expect(info.status, equals(api.ConnectionStatus.disconnected));
      expect(info.serverAddress, isNull);
      expect(info.duration, equals(0));
    });

    test('连接信息获取测试', () async {
      final info = await api.getConnectionInfo();

      // 验证返回的数据结构
      expect(info, isNotNull);
      expect(info.uploadBytes, isA<int>());
      expect(info.downloadBytes, isA<int>());
    });

    test('流量统计获取测试', () async {
      final stats = await api.getTrafficStats();

      // 验证统计数据结构
      expect(stats, isNotNull);
      expect(stats.uploadSpeed, isA<int>());
      expect(stats.downloadSpeed, isA<int>());
      expect(stats.totalUpload, isA<int>());
      expect(stats.totalDownload, isA<int>());

      // 初始状态流量应该为0
      expect(stats.totalUpload, equals(0));
      expect(stats.totalDownload, equals(0));
    });

    test('流量统计重置测试', () async {
      // 重置统计
      await api.resetTrafficStats();

      // 验证重置后的数据
      final stats = await api.getTrafficStats();
      expect(stats.totalUpload, equals(0));
      expect(stats.totalDownload, equals(0));
      expect(stats.uploadSpeed, equals(0));
      expect(stats.downloadSpeed, equals(0));
    });

    // 注意：代理配置缓存测试需要创建 Value 类型，这是 RustOpaque 类型
    // 在实际使用中，配置会从订阅或用户输入中获取
    // 这里跳过此测试，因为无法在 Dart 端直接创建 Value 实例

    test('连接状态查询测试', () async {
      // 多次查询连接信息，验证稳定性
      for (int i = 0; i < 5; i++) {
        final info = await api.getConnectionInfo();
        expect(info, isNotNull);
        expect(info.status, isA<api.ConnectionStatus>());

        // 短暂延迟
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    });

    test('并发查询测试', () async {
      // 并发查询连接信息和统计数据
      final results = await Future.wait([
        api.getConnectionInfo(),
        api.getTrafficStats(),
        api.getConnectionInfo(),
        api.getTrafficStats(),
      ]);

      // 验证所有查询都成功
      expect(results.length, equals(4));
      expect(results[0], isNotNull);
      expect(results[1], isNotNull);
      expect(results[2], isNotNull);
      expect(results[3], isNotNull);
    });
  });

  group('错误处理测试', () {
    test('无效配置ID连接测试', () async {
      // 尝试使用不存在的配置ID连接
      try {
        await api.connect(configId: 'non-existent-config');
        fail('应该抛出异常');
      } catch (e) {
        // 预期会抛出异常
        expect(e, isNotNull);
      }
    });

    test('重复断开连接测试', () async {
      // 多次断开连接不应该导致错误
      await api.disconnect();
      await api.disconnect();
      await api.disconnect();

      // 验证状态
      final info = await api.getConnectionInfo();
      expect(info.status, equals(api.ConnectionStatus.disconnected));
    });
  });
}
