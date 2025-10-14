/// V8Ray 节点选择器组件
///
/// 提供节点选择功能

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers/index.dart';
import 'loading_overlay.dart';

/// 节点选择器组件
class NodeSelector extends ConsumerWidget {
  const NodeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final serverState = ref.watch(serverProvider);
    final connectionState = ref.watch(connectionProvider);

    // 如果正在连接，禁用选择
    final isDisabled = connectionState.isConnecting || 
                       connectionState.isConnected ||
                       connectionState.isDisconnecting;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题
            Row(
              children: [
                Icon(
                  Icons.dns,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.nodeSelection,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                // 刷新按钮
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: l10n.refresh,
                  onPressed: isDisabled
                      ? null
                      : () => ref.read(serverProvider.notifier).refreshServers(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 服务器列表
            if (serverState.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: ListSkeletonLoader(
                  itemCount: 2,
                  itemHeight: 60,
                  spacing: 8,
                ),
              )
            else if (serverState.errorMessage != null)
              _buildErrorWidget(context, serverState.errorMessage!)
            else if (!serverState.hasServers)
              _buildEmptyWidget(context, l10n)
            else
              _buildServerList(context, ref, serverState, isDisabled),
          ],
        ),
      ),
    );
  }

  /// 构建错误提示
  Widget _buildErrorWidget(BuildContext context, String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态提示
  Widget _buildEmptyWidget(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noServersAvailable,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.pleaseUpdateSubscription,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  /// 构建服务器列表
  Widget _buildServerList(
    BuildContext context,
    WidgetRef ref,
    ServerState serverState,
    bool isDisabled,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 当前选中的服务器
        if (serverState.hasSelectedServer)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serverState.selectedServer!.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${serverState.selectedServer!.address}:${serverState.selectedServer!.port}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
                // 更改按钮
                TextButton(
                  onPressed: isDisabled
                      ? null
                      : () => _showServerSelectionDialog(context, ref, serverState),
                  child: Text(l10n.change),
                ),
              ],
            ),
          )
        else
          // 没有选中服务器时显示选择按钮
          OutlinedButton.icon(
            onPressed: isDisabled
                ? null
                : () => _showServerSelectionDialog(context, ref, serverState),
            icon: const Icon(Icons.add),
            label: Text(l10n.selectNode),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

        // 服务器数量提示
        const SizedBox(height: 8),
        Text(
          '${l10n.totalServers}: ${serverState.servers.length}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 显示服务器选择对话框
  void _showServerSelectionDialog(
    BuildContext context,
    WidgetRef ref,
    ServerState serverState,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => _ServerSelectionDialog(serverState: serverState),
    );
  }
}

/// 服务器选择对话框
class _ServerSelectionDialog extends ConsumerWidget {
  final ServerState serverState;

  const _ServerSelectionDialog({required this.serverState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.selectNode),
      content: SizedBox(
        width: 500,
        height: 400,
        child: ListView.builder(
          itemCount: serverState.servers.length,
          itemBuilder: (context, index) {
            final server = serverState.servers[index];
            final isSelected = server.id == serverState.selectedServerId;

            return ListTile(
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
              title: Text(server.name),
              subtitle: Text('${server.address}:${server.port} (${server.protocol})'),
              selected: isSelected,
              onTap: () {
                ref.read(serverProvider.notifier).selectServer(server.id);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

