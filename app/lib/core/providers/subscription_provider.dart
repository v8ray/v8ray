/// V8Ray 订阅状态管理
///
/// 管理订阅URL和订阅更新

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
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

  /// 最后更新时间
  final DateTime? lastUpdateTime;

  /// 节点数量
  final int nodeCount;

  const SubscriptionUpdateState({
    this.isUpdating = false,
    this.progress = 0.0,
    this.errorMessage,
    this.lastUpdateTime,
    this.nodeCount = 0,
  });

  SubscriptionUpdateState copyWith({
    bool? isUpdating,
    double? progress,
    String? errorMessage,
    DateTime? lastUpdateTime,
    int? nodeCount,
  }) {
    return SubscriptionUpdateState(
      isUpdating: isUpdating ?? this.isUpdating,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      nodeCount: nodeCount ?? this.nodeCount,
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
  Future<void> updateSubscription(String url) async {
    try {
      appLogger.info('Updating subscription...');

      state = state.copyWith(
        isUpdating: true,
        progress: 0.0,
        errorMessage: null,
      );

      // TODO: 实际的订阅更新逻辑将在后续Sprint中实现
      // 这里只是模拟更新过程
      for (var i = 0; i <= 100; i += 10) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        state = state.copyWith(progress: i / 100);
      }

      state = state.copyWith(
        isUpdating: false,
        progress: 1.0,
        lastUpdateTime: DateTime.now(),
        nodeCount: 25, // 模拟数据
      );

      appLogger.info('Subscription updated successfully');
    } catch (e, stackTrace) {
      appLogger.error('Failed to update subscription', e, stackTrace);

      state = state.copyWith(
        isUpdating: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 重置状态
  void reset() {
    state = const SubscriptionUpdateState();
  }
}
