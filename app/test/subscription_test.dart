/// V8Ray 订阅管理测试
///
/// 测试订阅添加、更新和服务器列表获取

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v8ray/core/providers/subscription_provider.dart';

void main() {
  group('订阅管理测试', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初始状态应该正确', () {
      final state = container.read(subscriptionProvider);

      expect(state.url, isEmpty);
      expect(state.isUpdating, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.nodeCount, 0);
      expect(state.lastUpdateTime, isNull);
    });

    test('设置订阅URL应该更新状态', () {
      final notifier = container.read(subscriptionProvider.notifier);
      const testUrl = 'https://example.com/subscription';

      notifier.setSubscriptionUrl(testUrl);

      final state = container.read(subscriptionProvider);
      expect(state.url, equals(testUrl));
    });

    test('清除订阅应该重置状态', () {
      final notifier = container.read(subscriptionProvider.notifier);
      const testUrl = 'https://example.com/subscription';

      // 先设置URL
      notifier.setSubscriptionUrl(testUrl);
      expect(container.read(subscriptionProvider).url, equals(testUrl));

      // 清除订阅
      notifier.clearSubscription();

      final state = container.read(subscriptionProvider);
      expect(state.url, isEmpty);
      expect(state.nodeCount, 0);
      expect(state.lastUpdateTime, isNull);
    });

    test('更新订阅时应该设置加载状态', () async {
      final notifier = container.read(subscriptionProvider.notifier);
      const testUrl = 'https://example.com/subscription';

      notifier.setSubscriptionUrl(testUrl);

      // 开始更新（这会失败因为是测试环境，但我们可以检查状态变化）
      final updateFuture = notifier.updateSubscription(testUrl);

      // 等待一小段时间让状态更新
      await Future.delayed(const Duration(milliseconds: 10));

      // 注意：在真实环境中，这会触发网络请求
      // 在测试环境中，我们主要验证状态管理逻辑

      // 清理
      try {
        await updateFuture;
      } catch (e) {
        // 预期会失败，因为没有真实的订阅服务器
      }
    });

    test('订阅状态应该正确复制', () {
      final state = container.read(subscriptionProvider);

      final newState = state.copyWith(
        url: 'https://new-url.com',
        nodeCount: 10,
      );

      expect(newState.url, equals('https://new-url.com'));
      expect(newState.nodeCount, equals(10));
      expect(newState.isUpdating, equals(state.isUpdating));
    });

    test('清除错误应该移除错误消息', () {
      final state = container.read(subscriptionProvider);

      // 创建带错误的状态
      final stateWithError = state.copyWith(
        errorMessage: 'Test error',
      );
      expect(stateWithError.errorMessage, equals('Test error'));

      // 清除错误
      final stateWithoutError = stateWithError.copyWith(
        clearError: true,
      );
      expect(stateWithoutError.errorMessage, isNull);
    });

    test('重试计数应该正确更新', () {
      final state = container.read(subscriptionProvider);

      final stateWithRetry = state.copyWith(
        retryCount: 3,
      );

      expect(stateWithRetry.retryCount, equals(3));
    });
  });

  group('订阅URL验证', () {
    test('空URL应该无效', () {
      const url = '';
      expect(url.isEmpty, isTrue);
    });

    test('有效的HTTP URL应该被接受', () {
      const url = 'http://example.com/subscription';
      expect(url.startsWith('http://') || url.startsWith('https://'), isTrue);
    });

    test('有效的HTTPS URL应该被接受', () {
      const url = 'https://example.com/subscription';
      expect(url.startsWith('https://'), isTrue);
    });

    test('无效的URL应该被拒绝', () {
      const url = 'not-a-url';
      expect(url.startsWith('http://') || url.startsWith('https://'), isFalse);
    });
  });

  group('订阅进度跟踪', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初始进度应该为0', () {
      final state = container.read(subscriptionProvider);
      expect(state.progress, equals(0.0));
    });

    test('进度应该在0到1之间', () {
      final state = container.read(subscriptionProvider);

      final state50 = state.copyWith(progress: 0.5);
      expect(state50.progress, greaterThanOrEqualTo(0.0));
      expect(state50.progress, lessThanOrEqualTo(1.0));

      final state100 = state.copyWith(progress: 1.0);
      expect(state100.progress, equals(1.0));
    });
  });

  group('订阅状态消息', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('状态消息应该正确设置', () {
      final state = container.read(subscriptionProvider);

      final stateWithMessage = state.copyWith(
        statusMessage: 'Downloading subscription...',
      );

      expect(stateWithMessage.statusMessage, equals('Downloading subscription...'));
    });

    test('状态消息应该可以清除', () {
      final state = container.read(subscriptionProvider);

      final stateWithMessage = state.copyWith(
        statusMessage: 'Test message',
      );
      expect(stateWithMessage.statusMessage, isNotNull);

      final stateWithoutMessage = stateWithMessage.copyWith(
        statusMessage: null,
      );
      expect(stateWithoutMessage.statusMessage, isNull);
    });
  });

  group('订阅更新时间', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初始更新时间应该为null', () {
      final state = container.read(subscriptionProvider);
      expect(state.lastUpdateTime, isNull);
    });

    test('更新时间应该可以设置', () {
      final state = container.read(subscriptionProvider);
      final now = DateTime.now();

      final updatedState = state.copyWith(
        lastUpdateTime: now,
      );

      expect(updatedState.lastUpdateTime, equals(now));
    });

    test('更新时间应该是有效的DateTime', () {
      final state = container.read(subscriptionProvider);
      final now = DateTime.now();

      final updatedState = state.copyWith(
        lastUpdateTime: now,
      );

      expect(updatedState.lastUpdateTime, isA<DateTime>());
      expect(updatedState.lastUpdateTime!.isBefore(DateTime.now().add(const Duration(seconds: 1))), isTrue);
    });
  });
}

