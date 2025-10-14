/// V8Ray 订阅状态管理
///
/// 管理订阅URL和订阅更新

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../ffi/bridge/api.dart' as api;
import '../utils/logger.dart';
import '../utils/validators.dart';

/// 订阅URL Provider
final subscriptionUrlProvider =
    StateNotifierProvider<SubscriptionUrlNotifier, String>((ref) {
  return SubscriptionUrlNotifier();
});

/// 订阅URL状态管理
class SubscriptionUrlNotifier extends StateNotifier<String> {
  SubscriptionUrlNotifier() : super('') {
    _loadSubscriptionUrl();
  }

  /// 从本地存储加载订阅URL
  Future<void> _loadSubscriptionUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final url = prefs.getString(StorageKeys.lastSubscriptionUrl);

      if (url != null && url.isNotEmpty) {
        state = url;
        appLogger.info('Loaded subscription URL');
      }
    } catch (e, stackTrace) {
      appLogger.error('Failed to load subscription URL', e, stackTrace);
    }
  }

  /// 设置订阅URL
  Future<bool> setSubscriptionUrl(String url) async {
    try {
      // 验证URL
      if (!Validators.isValidSubscriptionUrl(url)) {
        appLogger.warning('Invalid subscription URL: $url');
        return false;
      }

      state = url;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.lastSubscriptionUrl, url);

      appLogger.info('Subscription URL saved');
      return true;
    } catch (e, stackTrace) {
      appLogger.error('Failed to save subscription URL', e, stackTrace);
      return false;
    }
  }

  /// 清空订阅URL
  Future<void> clearSubscriptionUrl() async {
    try {
      state = '';

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StorageKeys.lastSubscriptionUrl);

      appLogger.info('Subscription URL cleared');
    } catch (e, stackTrace) {
      appLogger.error('Failed to clear subscription URL', e, stackTrace);
    }
  }
}

/// 订阅更新状态
class SubscriptionUpdateState {
  /// 是否正在更新
  final bool isUpdating;

  /// 更新进度（0.0 - 1.0）
  final double progress;

  /// 错误消息
  final String? errorMessage;

  /// 错误对象
  final Object? error;

  /// 最后更新时间
  final DateTime? lastUpdateTime;

  /// 节点数量
  final int nodeCount;

  /// 重试次数
  final int retryCount;

  const SubscriptionUpdateState({
    this.isUpdating = false,
    this.progress = 0.0,
    this.errorMessage,
    this.error,
    this.lastUpdateTime,
    this.nodeCount = 0,
    this.retryCount = 0,
  });

  SubscriptionUpdateState copyWith({
    bool? isUpdating,
    double? progress,
    String? errorMessage,
    Object? error,
    DateTime? lastUpdateTime,
    int? nodeCount,
    int? retryCount,
    bool clearError = false,
  }) {
    return SubscriptionUpdateState(
      isUpdating: isUpdating ?? this.isUpdating,
      progress: progress ?? this.progress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      error: clearError ? null : (error ?? this.error),
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      nodeCount: nodeCount ?? this.nodeCount,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

/// 订阅更新状态Provider
final subscriptionUpdateProvider =
    StateNotifierProvider<SubscriptionUpdateNotifier, SubscriptionUpdateState>(
  (ref) => SubscriptionUpdateNotifier(),
);

/// 订阅更新状态管理
class SubscriptionUpdateNotifier
    extends StateNotifier<SubscriptionUpdateState> {
  SubscriptionUpdateNotifier() : super(const SubscriptionUpdateState());

  /// 更新订阅
  Future<void> updateSubscription(String url, {int retryCount = 0}) async {
    try {
      appLogger.info('Updating subscription... (attempt ${retryCount + 1})');

      state = state.copyWith(
        isUpdating: true,
        progress: 0.0,
        clearError: true,
        retryCount: retryCount,
      );

      // 调用 Rust FFI 添加或更新订阅
      state = state.copyWith(progress: 0.3);

      // 首先获取现有订阅
      final subscriptions = await api.getSubscriptions();
      String? subscriptionId;

      // 检查是否已存在相同URL的订阅
      final existing = subscriptions.where((s) => s.url == url).firstOrNull;

      if (existing != null) {
        // 更新现有订阅
        subscriptionId = existing.id;
        appLogger.info('Updating existing subscription: $subscriptionId');
        await api.updateSubscription(id: subscriptionId);
      } else {
        // 添加新订阅
        appLogger.info('Adding new subscription');
        subscriptionId = await api.addSubscription(
          name: 'My Subscription',
          url: url,
        );
        appLogger.info('Subscription added: $subscriptionId');
      }

      state = state.copyWith(progress: 0.7);

      // 获取服务器列表
      final servers = await api.getServersForSubscription(
        subscriptionId: subscriptionId,
      );

      state = state.copyWith(
        isUpdating: false,
        progress: 1.0,
        lastUpdateTime: DateTime.now(),
        nodeCount: servers.length,
        retryCount: 0,
      );

      appLogger.info('Subscription updated successfully: ${servers.length} servers');
    } catch (e, stackTrace) {
      appLogger.error('Failed to update subscription', e, stackTrace);

      state = state.copyWith(
        isUpdating: false,
        errorMessage: e.toString(),
        error: e,
        retryCount: retryCount,
      );

      // 重新抛出错误以便上层处理
      rethrow;
    }
  }

  /// 重置状态
  void reset() {
    state = const SubscriptionUpdateState();
  }
}
