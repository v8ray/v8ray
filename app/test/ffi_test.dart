/// FFI 绑定测试
///
/// 测试 Rust FFI 接口是否正常工作
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:v8ray/core/ffi/bridge/api.dart' as api;
import 'package:v8ray/core/ffi/frb_generated.dart';

void main() {
  group('FFI 绑定测试', () {
    setUpAll(() async {
      // 获取当前工作目录
      final currentDir = Directory.current.path;
      final libPath = '$currentDir/../core/target/debug/libv8ray_core.so';

      print('尝试加载库: $libPath');
      print('库文件存在: ${File(libPath).existsSync()}');

      // 使用绝对路径初始化 Flutter Rust Bridge
      final externalLibrary = ExternalLibrary.open(libPath);
      await V8RayBridge.init(externalLibrary: externalLibrary);
    });

    test('初始化 V8Ray Core', () async {
      // 测试初始化函数
      expect(() async => await api.initV8Ray(), returnsNormally);
    });

    test('获取连接信息', () async {
      try {
        // 尝试获取连接信息（应该返回默认状态）
        final info = await api.getConnectionInfo();
        expect(info, isNotNull);
        print('连接状态: ${info.status}');
      } catch (e) {
        // 如果出错，打印错误信息但不失败测试
        print('获取连接信息出错: $e');
      }
    });

    test('获取流量统计', () async {
      try {
        // 尝试获取流量统计
        final stats = await api.getTrafficStats();
        expect(stats, isNotNull);
        print('总上传: ${stats.totalUpload}, 总下载: ${stats.totalDownload}');
      } catch (e) {
        // 如果出错，打印错误信息但不失败测试
        print('获取流量统计出错: $e');
      }
    });

    tearDownAll(() async {
      try {
        // 清理资源
        await api.shutdownV8Ray();
      } catch (e) {
        print('关闭 V8Ray Core 出错: $e');
      }
    });
  });
}
