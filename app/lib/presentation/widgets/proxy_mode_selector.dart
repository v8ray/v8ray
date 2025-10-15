/// V8Ray 代理模式选择组件
///
/// 提供代理模式选择功能（全局/智能分流）

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/connection_provider.dart';
import '../../core/providers/proxy_mode_provider.dart';

/// 代理模式选择组件
class ProxyModeSelector extends ConsumerWidget {
  const ProxyModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final proxyMode = ref.watch(proxyModeProvider);
    final connectionState = ref.watch(connectionProvider);
    final isConnected = connectionState.isConnected;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Text(
                  l10n.proxyMode,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (isConnected) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.lock,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.6),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // 模式选择
            SegmentedButton<ProxyMode>(
              segments: [
                ButtonSegment<ProxyMode>(
                  value: ProxyMode.global,
                  label: Text(l10n.globalMode),
                  icon: const Icon(Icons.public),
                ),
                ButtonSegment<ProxyMode>(
                  value: ProxyMode.smart,
                  label: Text(l10n.smartMode),
                  icon: const Icon(Icons.auto_awesome),
                ),
              ],
              selected: {proxyMode},
              onSelectionChanged:
                  isConnected
                      ? (Set<ProxyMode> newSelection) {
                        // 显示提示信息
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.disconnectToChangeProxyMode),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                      : (Set<ProxyMode> newSelection) {
                        ref
                            .read(proxyModeProvider.notifier)
                            .setProxyMode(newSelection.first);
                      },
              showSelectedIcon: false,
            ),

            const SizedBox(height: 12),

            // 模式说明
            _buildModeDescription(context, l10n, proxyMode, isConnected),
          ],
        ),
      ),
    );
  }

  /// 构建模式说明
  Widget _buildModeDescription(
    BuildContext context,
    AppLocalizations l10n,
    ProxyMode mode,
    bool isConnected,
  ) {
    String description;
    IconData icon;
    Color color;

    switch (mode) {
      case ProxyMode.global:
        description = l10n.globalModeDescription;
        icon = Icons.public;
        color = Theme.of(context).colorScheme.primary;
        break;
      case ProxyMode.smart:
        description = l10n.smartModeDescription;
        icon = Icons.auto_awesome;
        color = Theme.of(context).colorScheme.tertiary;
        break;
      case ProxyMode.direct:
        description = l10n.directModeDescription;
        icon = Icons.link_off;
        color = Theme.of(context).colorScheme.secondary;
        break;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
        if (isConnected) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.disconnectToChangeProxyMode,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
