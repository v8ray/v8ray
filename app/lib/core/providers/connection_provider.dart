/// V8Ray 连接状态管理
///
/// 管理代理连接状态

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../utils/logger.dart';

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
  return ConnectionNotifier();
});

/// 连接状态管理
class ConnectionNotifier extends StateNotifier<ProxyConnectionState> {
  ConnectionNotifier() : super(const ProxyConnectionState());

  /// 开始连接
  Future<void> connect(String nodeName) async {
    try {
      appLogger.info('Connecting to node: $nodeName');

      state = state.copyWith(
        status: ConnectionStatus.connecting,
        nodeName: nodeName,
        errorMessage: null,
      );

      // TODO: 实际的连接逻辑将在后续Sprint中实现
      // 这里只是模拟状态变化
      await Future<void>.delayed(const Duration(seconds: 2));

      state = state.copyWith(
        status: ConnectionStatus.connected,
        latency: 45,
        connectedDuration: Duration.zero,
      );

      appLogger.info('Connected to node: $nodeName');
    } catch (e, stackTrace) {
      appLogger.error('Failed to connect', e, stackTrace);

      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    try {
      appLogger.info('Disconnecting...');

      state = state.copyWith(
        status: ConnectionStatus.disconnecting,
        errorMessage: null,
      );

      // TODO: 实际的断开逻辑将在后续Sprint中实现
      await Future<void>.delayed(const Duration(seconds: 1));

      state = const ProxyConnectionState(
        status: ConnectionStatus.disconnected,
      );

      appLogger.info('Disconnected');
    } catch (e, stackTrace) {
      appLogger.error('Failed to disconnect', e, stackTrace);

      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: e.toString(),
      );
    }
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
