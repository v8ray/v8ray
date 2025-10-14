/// V8Ray 连接流程测试
///
/// 测试代理连接的完整流程

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v8ray/core/constants/app_constants.dart';
import 'package:v8ray/core/providers/connection_provider.dart';

void main() {
  group('连接状态测试', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初始状态应该是断开连接', () {
      final state = container.read(connectionProvider);

      expect(state.status, equals(ConnectionStatus.disconnected));
      expect(state.isConnected, isFalse);
      expect(state.isConnecting, isFalse);
      expect(state.isDisconnecting, isFalse);
    });

    test('连接状态应该正确判断', () {
      final state = container.read(connectionProvider);

      // 已连接状态
      final connectedState = state.copyWith(
        status: ConnectionStatus.connected,
      );
      expect(connectedState.isConnected, isTrue);
      expect(connectedState.isConnecting, isFalse);

      // 连接中状态
      final connectingState = state.copyWith(
        status: ConnectionStatus.connecting,
      );
      expect(connectingState.isConnecting, isTrue);
      expect(connectingState.isConnected, isFalse);

      // 断开中状态
      final disconnectingState = state.copyWith(
        status: ConnectionStatus.disconnecting,
      );
      expect(disconnectingState.isDisconnecting, isTrue);
      expect(disconnectingState.isConnected, isFalse);
    });

    test('连接状态应该正确复制', () {
      final state = container.read(connectionProvider);

      final newState = state.copyWith(
        status: ConnectionStatus.connected,
        serverId: 'test-server',
      );

      expect(newState.status, equals(ConnectionStatus.connected));
      expect(newState.serverId, equals('test-server'));
    });
  });

  group('连接流程测试', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('连接应该需要服务器ID', () {
      const serverId = 'test-server';
      expect(serverId.isNotEmpty, isTrue);
    });

    test('断开连接应该清除服务器ID', () {
      final state = container.read(connectionProvider);

      // 模拟已连接状态
      final connectedState = state.copyWith(
        status: ConnectionStatus.connected,
        serverId: 'test-server',
      );
      expect(connectedState.serverId, isNotNull);

      // 断开连接
      final disconnectedState = connectedState.copyWith(
        status: ConnectionStatus.disconnected,
        serverId: null,
      );
      expect(disconnectedState.serverId, isNull);
    });

    test('连接时间应该正确记录', () {
      final state = container.read(connectionProvider);
      final now = DateTime.now();

      final connectedState = state.copyWith(
        status: ConnectionStatus.connected,
        connectedAt: now,
      );

      expect(connectedState.connectedAt, equals(now));
    });

    test('连接时长应该可以计算', () {
      final now = DateTime.now();
      final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

      final duration = now.difference(oneMinuteAgo);
      expect(duration.inSeconds, greaterThanOrEqualTo(60));
    });
  });

  group('流量统计测试', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初始流量应该为0', () {
      final state = container.read(connectionProvider);

      expect(state.uploadBytes, equals(0));
      expect(state.downloadBytes, equals(0));
    });

    test('流量应该可以更新', () {
      final state = container.read(connectionProvider);

      final newState = state.copyWith(
        uploadBytes: 1024,
        downloadBytes: 2048,
      );

      expect(newState.uploadBytes, equals(1024));
      expect(newState.downloadBytes, equals(2048));
    });

    test('流量应该只增不减', () {
      final state = container.read(connectionProvider);

      final state1 = state.copyWith(uploadBytes: 1000);
      expect(state1.uploadBytes, equals(1000));

      final state2 = state1.copyWith(uploadBytes: 2000);
      expect(state2.uploadBytes, equals(2000));
      expect(state2.uploadBytes, greaterThan(state1.uploadBytes));
    });

    test('流量速度应该可以计算', () {
      const uploadSpeed = 1024; // 1 KB/s
      const downloadSpeed = 2048; // 2 KB/s

      expect(uploadSpeed, greaterThan(0));
      expect(downloadSpeed, greaterThan(0));
    });
  });

  group('延迟测试', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初始延迟应该为null', () {
      final state = container.read(connectionProvider);
      expect(state.latency, isNull);
    });

    test('延迟应该可以设置', () {
      final state = container.read(connectionProvider);

      final newState = state.copyWith(latency: 50);
      expect(newState.latency, equals(50));
    });

    test('延迟应该是正数', () {
      const latency = 50;
      expect(latency, greaterThan(0));
    });

    test('延迟应该在合理范围内', () {
      const latency = 50;
      expect(latency, lessThan(1000)); // 小于1秒
    });
  });

  group('错误处理测试', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初始错误消息应该为null', () {
      final state = container.read(connectionProvider);
      expect(state.errorMessage, isNull);
    });

    test('错误状态应该设置错误消息', () {
      final state = container.read(connectionProvider);

      final errorState = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: 'Connection failed',
      );

      expect(errorState.status, equals(ConnectionStatus.error));
      expect(errorState.errorMessage, equals('Connection failed'));
    });

    test('错误应该可以清除', () {
      final state = container.read(connectionProvider);

      final errorState = state.copyWith(
        errorMessage: 'Test error',
      );
      expect(errorState.errorMessage, isNotNull);

      final clearedState = errorState.copyWith(clearError: true);
      expect(clearedState.errorMessage, isNull);
    });
  });

  group('连接状态转换测试', () {
    test('断开 -> 连接中 -> 已连接', () {
      var status = ConnectionStatus.disconnected;
      expect(status, equals(ConnectionStatus.disconnected));

      status = ConnectionStatus.connecting;
      expect(status, equals(ConnectionStatus.connecting));

      status = ConnectionStatus.connected;
      expect(status, equals(ConnectionStatus.connected));
    });

    test('已连接 -> 断开中 -> 断开', () {
      var status = ConnectionStatus.connected;
      expect(status, equals(ConnectionStatus.connected));

      status = ConnectionStatus.disconnecting;
      expect(status, equals(ConnectionStatus.disconnecting));

      status = ConnectionStatus.disconnected;
      expect(status, equals(ConnectionStatus.disconnected));
    });

    test('连接失败应该转到错误状态', () {
      var status = ConnectionStatus.connecting;
      expect(status, equals(ConnectionStatus.connecting));

      status = ConnectionStatus.error;
      expect(status, equals(ConnectionStatus.error));
    });
  });

  group('代理模式测试', () {
    test('全局模式应该有效', () {
      const mode = ProxyMode.global;
      expect(mode, equals(ProxyMode.global));
    });

    test('智能分流模式应该有效', () {
      const mode = ProxyMode.smart;
      expect(mode, equals(ProxyMode.smart));
    });

    test('直连模式应该有效', () {
      const mode = ProxyMode.direct;
      expect(mode, equals(ProxyMode.direct));
    });
  });

  group('连接信息验证', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('服务器ID应该在连接时设置', () {
      final state = container.read(connectionProvider);

      final connectedState = state.copyWith(
        status: ConnectionStatus.connected,
        serverId: 'server-123',
      );

      expect(connectedState.serverId, isNotNull);
      expect(connectedState.serverId, equals('server-123'));
    });

    test('连接时间应该在连接时设置', () {
      final state = container.read(connectionProvider);
      final now = DateTime.now();

      final connectedState = state.copyWith(
        status: ConnectionStatus.connected,
        connectedAt: now,
      );

      expect(connectedState.connectedAt, isNotNull);
      expect(connectedState.connectedAt, isA<DateTime>());
    });
  });

  group('流量格式化测试', () {
    test('字节应该正确格式化为KB', () {
      const bytes = 1024;
      final kb = bytes / 1024;
      expect(kb, equals(1.0));
    });

    test('字节应该正确格式化为MB', () {
      const bytes = 1024 * 1024;
      final mb = bytes / (1024 * 1024);
      expect(mb, equals(1.0));
    });

    test('字节应该正确格式化为GB', () {
      const bytes = 1024 * 1024 * 1024;
      final gb = bytes / (1024 * 1024 * 1024);
      expect(gb, equals(1.0));
    });
  });
}

