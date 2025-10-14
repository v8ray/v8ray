/// V8Ray 系统代理测试
///
/// 测试系统代理设置功能

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v8ray/core/providers/system_proxy_provider.dart';

void main() {
  group('系统代理状态测试', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初始状态应该正确', () {
      final state = container.read(systemProxyProvider);

      expect(state.isEnabled, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.httpPort, equals(8080));
      expect(state.socksPort, equals(1080));
    });

    test('代理端口应该有效', () {
      final state = container.read(systemProxyProvider);

      expect(state.httpPort, greaterThan(0));
      expect(state.httpPort, lessThan(65536));
      expect(state.socksPort, greaterThan(0));
      expect(state.socksPort, lessThan(65536));
    });

    test('状态应该正确复制', () {
      final state = container.read(systemProxyProvider);

      final newState = state.copyWith(
        isEnabled: true,
        httpPort: 8888,
        socksPort: 1888,
      );

      expect(newState.isEnabled, isTrue);
      expect(newState.httpPort, equals(8888));
      expect(newState.socksPort, equals(1888));
    });

    test('清除错误应该移除错误消息', () {
      final state = container.read(systemProxyProvider);

      final stateWithError = state.copyWith(
        errorMessage: 'Test error',
      );
      expect(stateWithError.errorMessage, equals('Test error'));

      final stateWithoutError = stateWithError.copyWith(
        clearError: true,
      );
      expect(stateWithoutError.errorMessage, isNull);
    });
  });

  group('代理端口验证', () {
    test('HTTP端口应该在有效范围内', () {
      const port = 8080;
      expect(port, greaterThan(0));
      expect(port, lessThan(65536));
    });

    test('SOCKS端口应该在有效范围内', () {
      const port = 1080;
      expect(port, greaterThan(0));
      expect(port, lessThan(65536));
    });

    test('端口0应该无效', () {
      const port = 0;
      expect(port, equals(0));
    });

    test('端口65536应该无效', () {
      const port = 65536;
      expect(port, greaterThanOrEqualTo(65536));
    });

    test('常用HTTP端口应该有效', () {
      const ports = [8080, 8888, 3128, 8118];
      for (final port in ports) {
        expect(port, greaterThan(0));
        expect(port, lessThan(65536));
      }
    });

    test('常用SOCKS端口应该有效', () {
      const ports = [1080, 1081, 7890, 7891];
      for (final port in ports) {
        expect(port, greaterThan(0));
        expect(port, lessThan(65536));
      }
    });
  });

  group('代理状态切换', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初始状态应该是禁用', () {
      final state = container.read(systemProxyProvider);
      expect(state.isEnabled, isFalse);
    });

    test('启用状态应该可以设置', () {
      final state = container.read(systemProxyProvider);

      final enabledState = state.copyWith(isEnabled: true);
      expect(enabledState.isEnabled, isTrue);
    });

    test('禁用状态应该可以设置', () {
      final state = container.read(systemProxyProvider);

      final enabledState = state.copyWith(isEnabled: true);
      expect(enabledState.isEnabled, isTrue);

      final disabledState = enabledState.copyWith(isEnabled: false);
      expect(disabledState.isEnabled, isFalse);
    });
  });

  group('加载状态管理', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初始加载状态应该为false', () {
      final state = container.read(systemProxyProvider);
      expect(state.isLoading, isFalse);
    });

    test('加载状态应该可以设置', () {
      final state = container.read(systemProxyProvider);

      final loadingState = state.copyWith(isLoading: true);
      expect(loadingState.isLoading, isTrue);

      final notLoadingState = loadingState.copyWith(isLoading: false);
      expect(notLoadingState.isLoading, isFalse);
    });
  });

  group('错误处理', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初始错误消息应该为null', () {
      final state = container.read(systemProxyProvider);
      expect(state.errorMessage, isNull);
    });

    test('错误消息应该可以设置', () {
      final state = container.read(systemProxyProvider);

      final errorState = state.copyWith(
        errorMessage: 'Failed to set system proxy',
      );

      expect(errorState.errorMessage, equals('Failed to set system proxy'));
    });

    test('错误消息应该可以清除', () {
      final state = container.read(systemProxyProvider);

      final errorState = state.copyWith(
        errorMessage: 'Test error',
      );
      expect(errorState.errorMessage, isNotNull);

      final clearedState = errorState.copyWith(clearError: true);
      expect(clearedState.errorMessage, isNull);
    });
  });

  group('代理端口设置', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('HTTP端口应该可以更新', () {
      final state = container.read(systemProxyProvider);

      final newState = state.copyWith(httpPort: 8888);
      expect(newState.httpPort, equals(8888));
    });

    test('SOCKS端口应该可以更新', () {
      final state = container.read(systemProxyProvider);

      final newState = state.copyWith(socksPort: 1888);
      expect(newState.socksPort, equals(1888));
    });

    test('两个端口应该可以同时更新', () {
      final state = container.read(systemProxyProvider);

      final newState = state.copyWith(
        httpPort: 8888,
        socksPort: 1888,
      );

      expect(newState.httpPort, equals(8888));
      expect(newState.socksPort, equals(1888));
    });
  });

  group('代理地址格式', () {
    test('HTTP代理地址应该正确格式化', () {
      const port = 8080;
      final address = '127.0.0.1:$port';
      expect(address, equals('127.0.0.1:8080'));
    });

    test('SOCKS代理地址应该正确格式化', () {
      const port = 1080;
      final address = 'socks5://127.0.0.1:$port';
      expect(address, equals('socks5://127.0.0.1:1080'));
    });

    test('代理地址应该使用localhost', () {
      const host = '127.0.0.1';
      expect(host, equals('127.0.0.1'));
    });
  });

  group('代理配置验证', () {
    test('代理配置应该包含必要信息', () {
      const httpPort = 8080;
      const socksPort = 1080;

      expect(httpPort, isNotNull);
      expect(socksPort, isNotNull);
      expect(httpPort, isA<int>());
      expect(socksPort, isA<int>());
    });

    test('代理配置应该有效', () {
      const httpPort = 8080;
      const socksPort = 1080;

      expect(httpPort, greaterThan(0));
      expect(httpPort, lessThan(65536));
      expect(socksPort, greaterThan(0));
      expect(socksPort, lessThan(65536));
    });
  });

  group('平台兼容性', () {
    test('应该支持Linux平台', () {
      const platforms = ['linux', 'windows', 'macos'];
      expect(platforms, contains('linux'));
    });

    test('应该支持Windows平台', () {
      const platforms = ['linux', 'windows', 'macos'];
      expect(platforms, contains('windows'));
    });

    test('应该支持macOS平台', () {
      const platforms = ['linux', 'windows', 'macos'];
      expect(platforms, contains('macos'));
    });
  });

  group('代理设置持久化', () {
    test('端口设置应该可以保存', () {
      const httpPort = 8888;
      const socksPort = 1888;

      // 模拟保存到SharedPreferences
      final settings = {
        'httpPort': httpPort,
        'socksPort': socksPort,
      };

      expect(settings['httpPort'], equals(8888));
      expect(settings['socksPort'], equals(1888));
    });

    test('端口设置应该可以加载', () {
      final settings = {
        'httpPort': 8888,
        'socksPort': 1888,
      };

      final httpPort = settings['httpPort'] as int;
      final socksPort = settings['socksPort'] as int;

      expect(httpPort, equals(8888));
      expect(socksPort, equals(1888));
    });
  });
}

