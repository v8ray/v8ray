/// V8Ray 仪表板标签页
///
/// 显示连接状态、流量统计和快速操作

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/connection_provider.dart';
import '../../../core/providers/server_provider.dart';
import '../../../core/utils/responsive.dart';
import '../../widgets/animated_list_item.dart';

/// 仪表板标签页
class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final connectionState = ref.watch(connectionProvider);
    final serverState = ref.watch(serverProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.all(
        Responsive(context).valueWhen(
          mobile: UIConstants.defaultPadding,
          tablet: UIConstants.largePadding,
          desktop: UIConstants.largePadding * 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 状态卡片行
          AnimatedListItem(
            index: 0,
            child: _buildStatusCards(
              context,
              l10n,
              connectionState,
              serverState,
            ),
          ),
          const SizedBox(height: UIConstants.defaultPadding),

          // 流量统计卡片
          AnimatedListItem(
            index: 1,
            child: _buildTrafficCard(context, l10n, connectionState),
          ),
          const SizedBox(height: UIConstants.defaultPadding),

          // 快速操作卡片
          AnimatedListItem(
            index: 2,
            child: _buildQuickActionsCard(context, ref, l10n, connectionState),
          ),
        ],
      ),
    );
  }

  /// 构建状态卡片行
  Widget _buildStatusCards(
    BuildContext context,
    AppLocalizations l10n,
    ProxyConnectionState connectionState,
    ServerState serverState,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        final cards = [
          _buildConnectionInfoCard(context, l10n, connectionState),
          _buildCurrentNodeCard(context, l10n, connectionState, serverState),
          _buildProxyModeCard(context, l10n),
          _buildSystemStatusCard(context, l10n, connectionState),
        ];

        if (isWide) {
          // 桌面端：2x2网格
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: UIConstants.defaultPadding),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: UIConstants.defaultPadding),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: UIConstants.defaultPadding),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        } else {
          // 移动端：垂直排列
          return Column(
            children:
                cards
                    .map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: UIConstants.defaultPadding,
                        ),
                        child: card,
                      ),
                    )
                    .toList(),
          );
        }
      },
    );
  }

  /// 构建连接信息卡片
  Widget _buildConnectionInfoCard(
    BuildContext context,
    AppLocalizations l10n,
    ProxyConnectionState state,
  ) {
    final statusColor = _getStatusColor(context, state.status);
    final statusText = _getStatusText(l10n, state.status);
    final duration = state.connectedDuration ?? Duration.zero;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  l10n.connectionInfo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.circle, size: 12, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (state.isConnected) ...[
              const SizedBox(height: 8),
              Text(
                '${l10n.connectionDuration}: ${_formatDuration(l10n, duration)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建当前节点卡片
  Widget _buildCurrentNodeCard(
    BuildContext context,
    AppLocalizations l10n,
    ProxyConnectionState connectionState,
    ServerState serverState,
  ) {
    final selectedServer = serverState.selectedServer;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dns,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.currentNodeInfo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (selectedServer != null) ...[
              Text(
                selectedServer.name,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${selectedServer.address}:${selectedServer.port}',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                selectedServer.protocol.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ] else ...[
              Text(
                l10n.noServersAvailable,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建代理模式卡片
  Widget _buildProxyModeCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.proxyModeInfo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.smartMode,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.smartModeDescription,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建系统状态卡片
  Widget _buildSystemStatusCard(
    BuildContext context,
    AppLocalizations l10n,
    ProxyConnectionState state,
  ) {
    final isRunning = state.isConnected || state.isConnecting;
    final statusColor =
        isRunning
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, size: 20, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  l10n.systemStatus,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.circle, size: 12, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  isRunning ? l10n.running : l10n.stopped,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.normal, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  /// 构建流量统计卡片
  Widget _buildTrafficCard(
    BuildContext context,
    AppLocalizations l10n,
    ProxyConnectionState state,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.trafficStatistics,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildTrafficItem(
                    context,
                    l10n,
                    Icons.upload,
                    l10n.totalUpload,
                    0, // TODO: 从traffic stats provider获取
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTrafficItem(
                    context,
                    l10n,
                    Icons.download,
                    l10n.totalDownload,
                    0, // TODO: 从traffic stats provider获取
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建流量项
  Widget _buildTrafficItem(
    BuildContext context,
    AppLocalizations l10n,
    IconData icon,
    String label,
    int bytes,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _formatBytes(bytes),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// 构建快速操作卡片
  Widget _buildQuickActionsCard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ProxyConnectionState state,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.quickActions,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed:
                      state.isConnecting || state.isDisconnecting
                          ? null
                          : () {
                            if (state.isConnected) {
                              ref
                                  .read(connectionProvider.notifier)
                                  .disconnect();
                            } else {
                              // 使用选中的服务器ID连接
                              final serverId =
                                  ref.read(serverProvider).selectedServerId;
                              if (serverId != null) {
                                ref
                                    .read(connectionProvider.notifier)
                                    .connect(serverId);
                              }
                            }
                          },
                  icon: Icon(state.isConnected ? Icons.stop : Icons.play_arrow),
                  label: Text(
                    state.isConnected ? l10n.disconnect : l10n.connect,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: 实现切换节点功能
                  },
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(l10n.switchNode),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO(dev): 实现更新订阅功能
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.updateSubscription),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO(dev): 实现测试延迟功能
                  },
                  icon: const Icon(Icons.speed),
                  label: Text(l10n.testLatency),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 获取状态颜色
  Color _getStatusColor(BuildContext context, ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Theme.of(context).colorScheme.primary;
      case ConnectionStatus.connecting:
      case ConnectionStatus.disconnecting:
        return Theme.of(context).colorScheme.tertiary;
      case ConnectionStatus.disconnected:
        return Theme.of(context).colorScheme.onSurfaceVariant;
      case ConnectionStatus.error:
        return Theme.of(context).colorScheme.error;
    }
  }

  /// 获取状态文本
  String _getStatusText(AppLocalizations l10n, ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return l10n.connected;
      case ConnectionStatus.connecting:
        return l10n.connecting;
      case ConnectionStatus.disconnecting:
        return l10n.disconnecting;
      case ConnectionStatus.disconnected:
        return l10n.disconnected;
      case ConnectionStatus.error:
        return l10n.error;
    }
  }

  /// 格式化字节数
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// 格式化时长
  String _formatDuration(AppLocalizations l10n, Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours ${l10n.hours} $minutes ${l10n.minutes}';
    } else if (minutes > 0) {
      return '$minutes ${l10n.minutes} $seconds ${l10n.seconds}';
    } else {
      return '$seconds ${l10n.seconds}';
    }
  }
}
