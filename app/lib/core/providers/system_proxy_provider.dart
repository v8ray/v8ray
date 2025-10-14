/// V8Ray 系统代理状态管理
///
/// 管理系统代理的启用和禁用

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../ffi/bridge/api.dart' as api;
import '../utils/logger.dart';

/// 系统代理状态
class SystemProxyState {
  /// 是否已启用
  final bool isEnabled;

  /// 是否正在操作中
  final bool isLoading;

  /// 错误消息
  final String? errorMessage;

  /// HTTP 代理端口
  final int httpPort;

  /// SOCKS 代理端口
  final int socksPort;

  const SystemProxyState({
    this.isEnabled = false,
    this.isLoading = false,
    this.errorMessage,
    this.httpPort = 8080,
    this.socksPort = 1080,
  });

  SystemProxyState copyWith({
    bool? isEnabled,
    bool? isLoading,
    String? errorMessage,
    int? httpPort,
    int? socksPort,
    bool clearError = false,
  }) {
    return SystemProxyState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      httpPort: httpPort ?? this.httpPort,
      socksPort: socksPort ?? this.socksPort,
    );
  }
}

/// 系统代理状态 Provider
final systemProxyProvider =
    StateNotifierProvider<SystemProxyNotifier, SystemProxyState>((ref) {
      return SystemProxyNotifier();
    });

/// 系统代理状态管理
class SystemProxyNotifier extends StateNotifier<SystemProxyState> {
  SystemProxyNotifier() : super(const SystemProxyState()) {
    _loadSettings();
    _checkProxyStatus();
  }

  /// 从本地存储加载设置
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final httpPort = prefs.getInt(StorageKeys.httpProxyPort) ?? 8080;
      final socksPort = prefs.getInt(StorageKeys.socksProxyPort) ?? 1080;

      state = state.copyWith(httpPort: httpPort, socksPort: socksPort);

      appLogger.info('Loaded proxy settings: HTTP=$httpPort, SOCKS=$socksPort');
    } catch (e, stackTrace) {
      appLogger.error('Failed to load proxy settings', e, stackTrace);
    }
  }

  /// 检查系统代理状态
  Future<void> _checkProxyStatus() async {
    try {
      // isSystemProxySet 是同步函数，可能抛出异常
      final isSet = api.isSystemProxySet();
      state = state.copyWith(isEnabled: isSet);
      appLogger.info('System proxy status: $isSet');
    } catch (e, stackTrace) {
      appLogger.error('Failed to check proxy status', e, stackTrace);
    }
  }

  /// 启用系统代理
  Future<void> enableSystemProxy() async {
    if (state.isLoading) return;

    try {
      appLogger.info('Enabling system proxy...');
      appLogger.info(
        'Current state: isEnabled=${state.isEnabled}, isLoading=${state.isLoading}',
      );

      state = state.copyWith(isLoading: true, clearError: true);
      appLogger.info('State updated: isLoading=true');

      // 调用 Rust FFI 设置系统代理（同步函数，可能抛出异常）
      try {
        appLogger.info(
          'Calling api.setSystemProxy with httpPort=${state.httpPort}, socksPort=${state.socksPort}',
        );
        api.setSystemProxy(
          httpPort: state.httpPort,
          socksPort: state.socksPort,
        );
        appLogger.info('api.setSystemProxy returned successfully');

        state = state.copyWith(isEnabled: true, isLoading: false);

        appLogger.info('System proxy enabled successfully');
      } catch (e) {
        // 检查是否是权限错误
        state = state.copyWith(isLoading: false, errorMessage: e.toString());
        appLogger.error('Failed to enable system proxy: $e');
        rethrow;
      }
    } catch (e, stackTrace) {
      appLogger.error('Failed to enable system proxy', e, stackTrace);

      state = state.copyWith(isLoading: false, errorMessage: e.toString());

      rethrow;
    }
  }

  /// 禁用系统代理
  Future<void> disableSystemProxy() async {
    if (state.isLoading) return;

    try {
      appLogger.info('Disabling system proxy...');

      state = state.copyWith(isLoading: true, clearError: true);

      // 调用 Rust FFI 清除系统代理（同步函数，可能抛出异常）
      try {
        api.clearSystemProxy();

        state = state.copyWith(isEnabled: false, isLoading: false);

        appLogger.info('System proxy disabled successfully');
      } catch (e) {
        state = state.copyWith(isLoading: false, errorMessage: e.toString());
        appLogger.error('Failed to disable system proxy: $e');
        rethrow;
      }
    } catch (e, stackTrace) {
      appLogger.error('Failed to disable system proxy', e, stackTrace);

      state = state.copyWith(isLoading: false, errorMessage: e.toString());

      rethrow;
    }
  }

  /// 切换系统代理状态
  Future<void> toggleSystemProxy() async {
    if (state.isEnabled) {
      await disableSystemProxy();
    } else {
      await enableSystemProxy();
    }
  }

  /// 设置代理端口
  Future<void> setProxyPorts({int? httpPort, int? socksPort}) async {
    try {
      final newHttpPort = httpPort ?? state.httpPort;
      final newSocksPort = socksPort ?? state.socksPort;

      state = state.copyWith(httpPort: newHttpPort, socksPort: newSocksPort);

      // 保存到本地存储
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(StorageKeys.httpProxyPort, newHttpPort);
      await prefs.setInt(StorageKeys.socksProxyPort, newSocksPort);

      appLogger.info(
        'Proxy ports updated: HTTP=$newHttpPort, SOCKS=$newSocksPort',
      );

      // 如果代理已启用，重新设置
      if (state.isEnabled) {
        await disableSystemProxy();
        await enableSystemProxy();
      }
    } catch (e, stackTrace) {
      appLogger.error('Failed to set proxy ports', e, stackTrace);
    }
  }

  /// 刷新代理状态
  Future<void> refreshStatus() async {
    await _checkProxyStatus();
  }
}
