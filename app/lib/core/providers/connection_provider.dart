/// V8Ray 连接状态管理
///
/// 管理代理连接状态

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../ffi/bridge/api.dart' as api;
import '../utils/logger.dart';
import 'proxy_mode_provider.dart';
import 'system_proxy_provider.dart';

/// 连接状态数据模型
class ProxyConnectionState {
  /// 连接状态
  final ConnectionStatus status;

  /// 当前节点名称
  final String? nodeName;

  /// 延迟（毫秒）
  final int? latency;

  /// 上传速度（字节/秒）
  final int uploadSpeed;

  /// 下载速度（字节/秒）
  final int downloadSpeed;

  /// 已上传字节数
  final int uploadedBytes;

  /// 已下载字节数
  final int downloadedBytes;

  /// 连接时长
  final Duration? connectedDuration;

  /// 错误消息
  final String? errorMessage;

  const ProxyConnectionState({
    this.status = ConnectionStatus.disconnected,
    this.nodeName,
    this.latency,
    this.uploadSpeed = 0,
    this.downloadSpeed = 0,
    this.uploadedBytes = 0,
    this.downloadedBytes = 0,
    this.connectedDuration,
    this.errorMessage,
  });

  /// 创建副本
  ProxyConnectionState copyWith({
    ConnectionStatus? status,
    String? nodeName,
    int? latency,
    int? uploadSpeed,
    int? downloadSpeed,
    int? uploadedBytes,
    int? downloadedBytes,
    Duration? connectedDuration,
    String? errorMessage,
  }) {
    return ProxyConnectionState(
      status: status ?? this.status,
      nodeName: nodeName ?? this.nodeName,
      latency: latency ?? this.latency,
      uploadSpeed: uploadSpeed ?? this.uploadSpeed,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      uploadedBytes: uploadedBytes ?? this.uploadedBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      connectedDuration: connectedDuration ?? this.connectedDuration,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// 是否已连接
  bool get isConnected => status == ConnectionStatus.connected;

  /// 是否正在连接
  bool get isConnecting => status == ConnectionStatus.connecting;

  /// 是否已断开
  bool get isDisconnected => status == ConnectionStatus.disconnected;

  /// 是否有错误
  bool get hasError => status == ConnectionStatus.error;

  /// 是否正在断开连接
  bool get isDisconnecting => status == ConnectionStatus.disconnecting;
}

/// 连接状态Provider
final connectionProvider =
    StateNotifierProvider<ConnectionNotifier, ProxyConnectionState>((ref) {
      return ConnectionNotifier(ref);
    });

/// 连接状态管理
class ConnectionNotifier extends StateNotifier<ProxyConnectionState> {
  ConnectionNotifier(this._ref) : super(const ProxyConnectionState());

  final Ref _ref;
  Timer? _statsTimer;

  /// 开始连接
  Future<void> connect(String serverId) async {
    try {
      appLogger.info('Connecting to server: $serverId');

      // 1. 从数据库获取服务器配置（先获取以便显示节点名称）
      final serverConfig = await api.getServerConfig(serverId: serverId);
      appLogger.info('Retrieved server config: ${serverConfig.name}');

      state = state.copyWith(
        status: ConnectionStatus.connecting,
        nodeName: serverConfig.name, // 使用服务器名称而不是 ID
        errorMessage: null,
      );

      // 2. 获取当前代理模式
      final proxyMode = _ref.read(proxyModeProvider);
      final modeString = _proxyModeToString(proxyMode);
      appLogger.info('Setting proxy mode: $modeString');
      await api.setProxyMode(mode: modeString);

      // 3. 缓存配置到连接管理器
      await api.cacheProxyConfig(configId: serverId, config: serverConfig);
      appLogger.info('Config cached for server: $serverId');

      // 4. 调用 Rust FFI 连接函数
      await api.connect(configId: serverId);

      state = state.copyWith(
        status: ConnectionStatus.connected,
        connectedDuration: Duration.zero,
      );

      // 5. 自动启用系统代理
      try {
        appLogger.info('Auto-enabling system proxy...');
        await _ref.read(systemProxyProvider.notifier).enableSystemProxy();
        appLogger.info('System proxy enabled automatically');
      } catch (e) {
        appLogger.warning('Failed to enable system proxy automatically: $e');
        // 不影响连接状态，只记录警告
      }

      // 启动统计数据定时更新
      _startStatsTimer();

      appLogger.info('Connected to server: $serverId');
    } catch (e, stackTrace) {
      appLogger.error('Failed to connect', e, stackTrace);

      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: e.toString(),
      );
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

  /// 断开连接
  Future<void> disconnect() async {
    try {
      appLogger.info('Disconnecting...');

      state = state.copyWith(status: ConnectionStatus.disconnecting);

      // 停止统计数据定时器
      _stopStatsTimer();

      // 调用 Rust FFI 断开函数
      await api.disconnect();

      // 自动禁用系统代理
      try {
        appLogger.info('Auto-disabling system proxy...');
        await _ref.read(systemProxyProvider.notifier).disableSystemProxy();
        appLogger.info('System proxy disabled automatically');
      } catch (e) {
        appLogger.warning('Failed to disable system proxy automatically: $e');
        // 不影响断开状态，只记录警告
      }

      state = const ProxyConnectionState(status: ConnectionStatus.disconnected);

      appLogger.info('Disconnected');
    } catch (e, stackTrace) {
      appLogger.error('Failed to disconnect', e, stackTrace);

      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 启动统计数据定时器
  void _startStatsTimer() {
    _stopStatsTimer();
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        final info = await api.getConnectionInfo();
        final stats = await api.getTrafficStats();

        state = state.copyWith(
          uploadSpeed: stats.uploadSpeed.toInt(),
          downloadSpeed: stats.downloadSpeed.toInt(),
          uploadedBytes: stats.totalUpload.toInt(),
          downloadedBytes: stats.totalDownload.toInt(),
          connectedDuration: Duration(seconds: info.duration.toInt()),
        );
      } catch (e) {
        appLogger.error('Failed to update stats', e);
      }
    });
  }

  /// 停止统计数据定时器
  void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  @override
  void dispose() {
    _stopStatsTimer();
    super.dispose();
  }

  /// 更新统计数据
  void updateStats({
    int? uploadSpeed,
    int? downloadSpeed,
    int? uploadedBytes,
    int? downloadedBytes,
    Duration? connectedDuration,
  }) {
    state = state.copyWith(
      uploadSpeed: uploadSpeed,
      downloadSpeed: downloadSpeed,
      uploadedBytes: uploadedBytes,
      downloadedBytes: downloadedBytes,
      connectedDuration: connectedDuration,
    );
  }

  /// 更新延迟
  void updateLatency(int latency) {
    state = state.copyWith(latency: latency);
  }

  /// 重置状态
  void reset() {
    state = const ProxyConnectionState();
  }
}
