/// V8Ray 连接/断开按钮组件
///
/// 提供连接和断开代理的功能

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/connection_provider.dart';
import '../../core/providers/subscription_provider.dart';

/// 连接/断开按钮组件
class ConnectionButton extends ConsumerWidget {
  const ConnectionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final connectionState = ref.watch(connectionProvider);
    final subscriptionUrl = ref.watch(subscriptionUrlProvider);

    // 判断是否可以连接
    final canConnect = subscriptionUrl.isNotEmpty &&
        !connectionState.isConnecting &&
        !connectionState.isDisconnecting;

    // 判断是否可以断开
    final canDisconnect =
        connectionState.isConnected || connectionState.isConnecting;

    return SizedBox(
      height: 56,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: UIConstants.animationDuration),
        child: connectionState.isConnected || connectionState.isConnecting
            ? _buildDisconnectButton(
                context,
                l10n,
                ref,
                canDisconnect,
                connectionState.isDisconnecting,
              )
            : _buildConnectButton(
                context,
                l10n,
                ref,
                canConnect,
                connectionState.isConnecting,
              ),
      ),
    );
  }

  /// 构建连接按钮
  Widget _buildConnectButton(
    BuildContext context,
    AppLocalizations l10n,
    WidgetRef ref,
    bool enabled,
    bool isConnecting,
  ) {
    return FilledButton.icon(
      key: const ValueKey('connect'),
      onPressed: enabled ? () => _handleConnect(context, ref) : null,
      icon: isConnecting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.play_arrow),
      label: Text(
        l10n.connect,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// 构建断开按钮
  Widget _buildDisconnectButton(
    BuildContext context,
    AppLocalizations l10n,
    WidgetRef ref,
    bool enabled,
    bool isDisconnecting,
  ) {
    return FilledButton.icon(
      key: const ValueKey('disconnect'),
      onPressed: enabled ? () => _handleDisconnect(ref) : null,
      icon: isDisconnecting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.stop),
      label: Text(
        l10n.disconnect,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  /// 处理连接
  Future<void> _handleConnect(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final subscriptionUrl = ref.read(subscriptionUrlProvider);

    if (subscriptionUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseEnterUrl),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // TODO: 实际应该从订阅中选择一个节点
    // 这里暂时使用模拟数据
    await ref.read(connectionProvider.notifier).connect('Test Node');

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
}
