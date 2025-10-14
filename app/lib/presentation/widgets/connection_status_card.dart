/// V8Ray 连接状态卡片组件
///
/// 显示当前连接状态、节点信息、延迟和速度

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/connection_provider.dart';
import '../../core/providers/server_provider.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

/// 连接状态卡片组件
class ConnectionStatusCard extends ConsumerWidget {
  const ConnectionStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final connectionState = ref.watch(connectionProvider);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 连接状态指示器（可点击）
            _buildStatusIndicator(context, ref, l10n, connectionState),
            const SizedBox(height: 20),

            // 节点信息
            if (connectionState.isConnected ||
                connectionState.isConnecting) ...[
              _buildNodeInfo(context, l10n, connectionState),
              const SizedBox(height: 16),

              // 速度信息
              _buildSpeedInfo(context, l10n, connectionState),
            ] else ...[
              Text(
                l10n.disconnected,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建状态指示器（可点击按钮）
  Widget _buildStatusIndicator(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ProxyConnectionState state,
  ) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    bool canInteract = true;

    switch (state.status) {
      case ConnectionStatus.connected:
        statusColor = AppColors.connected;
        statusText = l10n.connected;
        statusIcon = Icons.check_circle;
        break;
      case ConnectionStatus.connecting:
        statusColor = AppColors.connecting;
        statusText = l10n.connecting;
        statusIcon = Icons.sync;
        canInteract = false;
        break;
      case ConnectionStatus.disconnecting:
        statusColor = AppColors.connecting;
        statusText = l10n.disconnecting;
        statusIcon = Icons.sync;
        canInteract = false;
        break;
      case ConnectionStatus.error:
        statusColor = AppColors.error;
        statusText = l10n.error;
        statusIcon = Icons.error;
        break;
      case ConnectionStatus.disconnected:
        statusColor = AppColors.disconnected;
        statusText = l10n.disconnected;
        statusIcon = Icons.circle;
        break;
    }

    // 是否是未连接状态
    final bool isDisconnected = state.status == ConnectionStatus.disconnected;

    return Column(
      children: [
        // 可点击的状态按钮
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canInteract
                ? () => _handleStatusTap(context, ref, state)
                : null,
            borderRadius: BorderRadius.circular(60),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDisconnected
                    ? statusColor.withOpacity(0.15)
                    : statusColor.withOpacity(0.1),
                border: Border.all(
                  color: statusColor,
                  width: isDisconnected ? 4 : 3,
                ),
                boxShadow: isDisconnected
                    ? [
                        BoxShadow(
                          color: statusColor.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 主图标
                  Icon(
                    statusIcon,
                    size: isDisconnected ? 55 : 50,
                    color: statusColor,
                  ),
                  // 连接中的旋转动画
                  if (state.status == ConnectionStatus.connecting ||
                      state.status == ConnectionStatus.disconnecting)
                    const SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                      ),
                    ),
                  // 未连接时的脉冲动画提示
                  if (isDisconnected)
                    Positioned.fill(
                      child: _PulseAnimation(
                        color: statusColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 状态文本
        Text(
          statusText,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: isDisconnected ? 22 : 20,
              ),
        ),

        // 提示文本
        if (canInteract) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDisconnected
                  ? statusColor.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: isDisconnected
                  ? Border.all(color: statusColor.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state.status == ConnectionStatus.connected
                      ? Icons.power_off
                      : Icons.power_settings_new,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Text(
                  state.status == ConnectionStatus.connected
                      ? l10n.disconnect
                      : l10n.connect,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: statusColor,
                        fontWeight: isDisconnected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                ),
              ],
            ),
          ),
        ],

        // 连接时长
        if (state.connectedDuration != null) ...[
          const SizedBox(height: 4),
          Text(
            Formatters.formatDuration(state.connectedDuration!),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }

  /// 处理状态按钮点击
  void _handleStatusTap(
    BuildContext context,
    WidgetRef ref,
    ProxyConnectionState state,
  ) {
    if (state.status == ConnectionStatus.connected) {
      // 断开连接
      _handleDisconnect(ref);
    } else if (state.status == ConnectionStatus.disconnected ||
        state.status == ConnectionStatus.error) {
      // 连接
      _handleConnect(context, ref);
    }
  }

  /// 处理连接
  Future<void> _handleConnect(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final serverState = ref.read(serverProvider);

    // 检查是否有选中的服务器
    if (!serverState.hasSelectedServer) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pleaseSelectNode),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    final selectedServer = serverState.selectedServer!;

    // 使用选中的服务器ID进行连接
    await ref.read(connectionProvider.notifier).connect(selectedServer.id);

    if (context.mounted) {
      final connectionState = ref.read(connectionProvider);
      if (connectionState.isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.connectSuccess),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } else if (connectionState.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.connectFailed}: ${connectionState.errorMessage}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 处理断开
  Future<void> _handleDisconnect(WidgetRef ref) async {
    await ref.read(connectionProvider.notifier).disconnect();
  }

  /// 构建节点信息
  Widget _buildNodeInfo(
    BuildContext context,
    AppLocalizations l10n,
    ProxyConnectionState state,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.dns,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.currentNode,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.nodeName ?? '-',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          if (state.latency != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.getLatencyColor(state.latency),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                Formatters.formatLatency(state.latency!),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建速度信息
  Widget _buildSpeedInfo(
    BuildContext context,
    AppLocalizations l10n,
    ProxyConnectionState state,
  ) {
    return Row(
      children: [
        // 上传速度
        Expanded(
          child: _buildSpeedItem(
            context,
            l10n.uploadSpeed,
            Icons.arrow_upward,
            Formatters.formatSpeed(state.uploadSpeed),
            Theme.of(context).colorScheme.tertiary,
          ),
        ),
        const SizedBox(width: 12),

        // 下载速度
        Expanded(
          child: _buildSpeedItem(
            context,
            l10n.downloadSpeed,
            Icons.arrow_downward,
            Formatters.formatSpeed(state.downloadSpeed),
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// 构建速度项
  Widget _buildSpeedItem(
    BuildContext context,
    String label,
    IconData icon,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

/// 脉冲动画组件 - 用于未连接状态的视觉提示
class _PulseAnimation extends StatefulWidget {
  final Color color;

  const _PulseAnimation({required this.color});

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final scale = 1.0 + (_animation.value * 0.3);
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(scale),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.color.withOpacity((1 - _animation.value) * 0.5),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }
}
