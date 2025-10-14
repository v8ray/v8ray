/// V8Ray 服务器/节点状态管理
///
/// 管理服务器列表和节点选择

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ffi/bridge/api.dart' as api;
import '../utils/logger.dart';

/// 服务器信息状态
class ServerState {
  /// 服务器列表
  final List<api.ServerInfo> servers;

  /// 当前选中的服务器ID
  final String? selectedServerId;

  /// 是否正在加载
  final bool isLoading;

  /// 错误消息
  final String? errorMessage;

  const ServerState({
    this.servers = const [],
    this.selectedServerId,
    this.isLoading = false,
    this.errorMessage,
  });

  ServerState copyWith({
    List<api.ServerInfo>? servers,
    String? selectedServerId,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ServerState(
      servers: servers ?? this.servers,
      selectedServerId: selectedServerId ?? this.selectedServerId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  /// 获取当前选中的服务器
  api.ServerInfo? get selectedServer {
    if (selectedServerId == null) return null;
    try {
      return servers.firstWhere((s) => s.id == selectedServerId);
    } catch (e) {
      return null;
    }
  }

  /// 是否有可用服务器
  bool get hasServers => servers.isNotEmpty;

  /// 是否有选中的服务器
  bool get hasSelectedServer => selectedServerId != null && selectedServer != null;
}

/// 服务器状态Provider
final serverProvider = StateNotifierProvider<ServerNotifier, ServerState>((ref) {
  return ServerNotifier();
});

/// 服务器状态管理
class ServerNotifier extends StateNotifier<ServerState> {
  ServerNotifier() : super(const ServerState()) {
    // 初始化时加载服务器列表
    loadServers();
  }

  /// 加载所有服务器
  Future<void> loadServers() async {
    try {
      appLogger.info('Loading servers...');

      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
      );

      // 调用 Rust FFI 获取服务器列表
      final servers = await api.getServers();

      appLogger.info('Loaded ${servers.length} servers');

      state = state.copyWith(
        servers: servers,
        isLoading: false,
      );

      // 如果有服务器但没有选中的，自动选择第一个
      if (servers.isNotEmpty && state.selectedServerId == null) {
        selectServer(servers.first.id);
      }
    } catch (e, stackTrace) {
      appLogger.error('Failed to load servers', e, stackTrace);

      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 加载指定订阅的服务器
  Future<void> loadServersForSubscription(String subscriptionId) async {
    try {
      appLogger.info('Loading servers for subscription: $subscriptionId');

      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
      );

      // 调用 Rust FFI 获取服务器列表
      final servers = await api.getServersForSubscription(
        subscriptionId: subscriptionId,
      );

      appLogger.info('Loaded ${servers.length} servers for subscription');

      state = state.copyWith(
        servers: servers,
        isLoading: false,
      );

      // 如果有服务器但没有选中的，自动选择第一个
      if (servers.isNotEmpty && state.selectedServerId == null) {
        selectServer(servers.first.id);
      }
    } catch (e, stackTrace) {
      appLogger.error('Failed to load servers for subscription', e, stackTrace);

      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 选择服务器
  void selectServer(String serverId) {
    appLogger.info('Selecting server: $serverId');

    state = state.copyWith(
      selectedServerId: serverId,
      errorMessage: null,
    );
  }

  /// 自动选择最优服务器
  /// 简单实现：选择第一个可用服务器
  /// TODO: 后续可以根据延迟、负载等因素智能选择
  void selectBestServer() {
    if (state.servers.isEmpty) {
      appLogger.warning('No servers available for selection');
      return;
    }

    // 简单实现：选择第一个服务器
    final bestServer = state.servers.first;
    selectServer(bestServer.id);

    appLogger.info('Auto-selected best server: ${bestServer.name}');
  }

  /// 清空服务器列表
  void clearServers() {
    state = const ServerState();
  }

  /// 刷新服务器列表
  Future<void> refreshServers() async {
    await loadServers();
  }
}

