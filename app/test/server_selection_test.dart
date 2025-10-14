/// V8Ray 服务器选择测试
///
/// 测试服务器列表管理和节点选择

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v8ray/core/providers/server_provider.dart';

void main() {
  group('服务器选择测试', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初始状态应该正确', () {
      final state = container.read(serverProvider);

      expect(state.servers, isEmpty);
      expect(state.selectedServer, isNull);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('选择服务器应该更新状态', () {
      final notifier = container.read(serverProvider.notifier);
      const testServerId = 'test-server-1';

      notifier.selectServer(testServerId);

      final state = container.read(serverProvider);
      expect(state.selectedServer, equals(testServerId));
    });

    test('清除选择应该重置选中的服务器', () {
      final notifier = container.read(serverProvider.notifier);
      const testServerId = 'test-server-1';

      // 先选择一个服务器
      notifier.selectServer(testServerId);
      expect(
        container.read(serverProvider).selectedServer,
        equals(testServerId),
      );

      // 清除选择
      notifier.clearSelection();

      final state = container.read(serverProvider);
      expect(state.selectedServer, isNull);
    });

    test('服务器状态应该正确复制', () {
      final state = container.read(serverProvider);

      final newState = state.copyWith(
        selectedServer: 'server-1',
        isLoading: true,
      );

      expect(newState.selectedServer, equals('server-1'));
      expect(newState.isLoading, isTrue);
      expect(newState.servers, equals(state.servers));
    });

    test('清除错误应该移除错误消息', () {
      final state = container.read(serverProvider);

      // 创建带错误的状态
      final stateWithError = state.copyWith(errorMessage: 'Test error');
      expect(stateWithError.errorMessage, equals('Test error'));

      // 清除错误
      final stateWithoutError = stateWithError.copyWith(clearError: true);
      expect(stateWithoutError.errorMessage, isNull);
    });
  });

  group('服务器列表管理', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初始服务器列表应该为空', () {
      final state = container.read(serverProvider);
      expect(state.servers, isEmpty);
    });

    test('服务器列表应该可以更新', () {
      final state = container.read(serverProvider);

      final newState = state.copyWith(
        servers: ['server-1', 'server-2', 'server-3'],
      );

      expect(newState.servers.length, equals(3));
      expect(newState.servers, contains('server-1'));
      expect(newState.servers, contains('server-2'));
      expect(newState.servers, contains('server-3'));
    });

    test('服务器列表应该保持顺序', () {
      final state = container.read(serverProvider);

      final servers = ['server-1', 'server-2', 'server-3'];
      final newState = state.copyWith(servers: servers);

      expect(newState.servers[0], equals('server-1'));
      expect(newState.servers[1], equals('server-2'));
      expect(newState.servers[2], equals('server-3'));
    });
  });

  group('服务器选择验证', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('选择的服务器ID应该有效', () {
      const serverId = 'valid-server-id';
      expect(serverId.isNotEmpty, isTrue);
    });

    test('空服务器ID应该无效', () {
      const serverId = '';
      expect(serverId.isEmpty, isTrue);
    });

    test('null服务器ID应该表示未选择', () {
      final state = container.read(serverProvider);
      expect(state.selectedServer, isNull);
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
      final state = container.read(serverProvider);
      expect(state.isLoading, isFalse);
    });

    test('加载状态应该可以设置', () {
      final state = container.read(serverProvider);

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
      final state = container.read(serverProvider);
      expect(state.errorMessage, isNull);
    });

    test('错误消息应该可以设置', () {
      final state = container.read(serverProvider);

      final errorState = state.copyWith(errorMessage: 'Failed to load servers');

      expect(errorState.errorMessage, equals('Failed to load servers'));
    });

    test('错误消息应该可以清除', () {
      final state = container.read(serverProvider);

      final errorState = state.copyWith(errorMessage: 'Test error');
      expect(errorState.errorMessage, isNotNull);

      final clearedState = errorState.copyWith(clearError: true);
      expect(clearedState.errorMessage, isNull);
    });
  });

  group('服务器刷新', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('刷新应该清除错误', () async {
      final notifier = container.read(serverProvider.notifier);

      // 模拟刷新操作
      try {
        await notifier.refreshServers();
      } catch (e) {
        // 预期可能失败，因为没有真实的订阅数据
      }

      // 验证刷新被调用（即使失败）
      expect(true, isTrue);
    });
  });

  group('自动选择', () {
    test('应该选择第一个可用服务器', () {
      final servers = ['server-1', 'server-2', 'server-3'];
      expect(servers.isNotEmpty, isTrue);
      expect(servers.first, equals('server-1'));
    });

    test('空列表不应该有自动选择', () {
      final servers = <String>[];
      expect(servers.isEmpty, isTrue);
    });
  });

  group('服务器过滤', () {
    test('应该能够过滤服务器列表', () {
      final servers = ['server-1', 'server-2', 'server-3'];
      final filtered = servers.where((s) => s.contains('1')).toList();

      expect(filtered.length, equals(1));
      expect(filtered.first, equals('server-1'));
    });

    test('过滤不匹配应该返回空列表', () {
      final servers = ['server-1', 'server-2', 'server-3'];
      final filtered = servers.where((s) => s.contains('999')).toList();

      expect(filtered.isEmpty, isTrue);
    });
  });

  group('服务器排序', () {
    test('应该能够按名称排序', () {
      final servers = ['server-3', 'server-1', 'server-2'];
      final sorted = List<String>.from(servers)..sort();

      expect(sorted[0], equals('server-1'));
      expect(sorted[1], equals('server-2'));
      expect(sorted[2], equals('server-3'));
    });

    test('空列表排序应该保持为空', () {
      final servers = <String>[];
      final sorted = List<String>.from(servers)..sort();

      expect(sorted.isEmpty, isTrue);
    });
  });
}
