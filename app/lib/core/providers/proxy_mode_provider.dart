/// V8Ray 代理模式状态管理
///
/// 管理代理模式（全局/智能分流/直连）

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../utils/logger.dart';

/// 代理模式Provider
final proxyModeProvider =
    StateNotifierProvider<ProxyModeNotifier, ProxyMode>((ref) {
  return ProxyModeNotifier();
});

/// 代理模式状态管理
class ProxyModeNotifier extends StateNotifier<ProxyMode> {
  ProxyModeNotifier() : super(ProxyMode.smart) {
    _loadProxyMode();
  }

  /// 从本地存储加载代理模式
  Future<void> _loadProxyMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = prefs.getString(StorageKeys.lastProxyMode);

      if (modeString != null) {
        state = _parseProxyMode(modeString);
        appLogger.info('Loaded proxy mode: $state');
      } else {
        // 默认使用智能分流
        state = ProxyMode.smart;
        appLogger.info('Using default proxy mode: smart');
      }
    } catch (e, stackTrace) {
      appLogger.error('Failed to load proxy mode', e, stackTrace);
      state = ProxyMode.smart;
    }
  }

  /// 设置代理模式
  Future<void> setProxyMode(ProxyMode mode) async {
    try {
      state = mode;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        StorageKeys.lastProxyMode,
        _proxyModeToString(mode),
      );

      appLogger.info('Proxy mode changed to: $mode');
    } catch (e, stackTrace) {
      appLogger.error('Failed to save proxy mode', e, stackTrace);
    }
  }

  /// 切换到全局模式
  Future<void> setGlobalMode() => setProxyMode(ProxyMode.global);

  /// 切换到智能分流模式
  Future<void> setSmartMode() => setProxyMode(ProxyMode.smart);

  /// 切换到直连模式
  Future<void> setDirectMode() => setProxyMode(ProxyMode.direct);

  /// 解析代理模式字符串
  ProxyMode _parseProxyMode(String value) {
    switch (value) {
      case 'global':
        return ProxyMode.global;
      case 'smart':
        return ProxyMode.smart;
      case 'direct':
        return ProxyMode.direct;
      default:
        return ProxyMode.smart;
    }
  }

  /// 将代理模式转换为字符串
  String _proxyModeToString(ProxyMode mode) {
    switch (mode) {
      case ProxyMode.global:
        return 'global';
      case ProxyMode.smart:
        return 'smart';
      case ProxyMode.direct:
        return 'direct';
    }
  }
}

