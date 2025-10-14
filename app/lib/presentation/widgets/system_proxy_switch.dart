/// V8Ray 系统代理开关组件
///
/// 提供系统代理的启用和禁用功能

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers/index.dart';

/// 系统代理开关组件
class SystemProxySwitch extends ConsumerWidget {
  /// 是否显示为卡片
  final bool asCard;

  /// 是否显示详细信息
  final bool showDetails;

  const SystemProxySwitch({
    this.asCard = true,
    this.showDetails = true,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final proxyState = ref.watch(systemProxyProvider);
    final theme = Theme.of(context);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和开关
        Row(
          children: [
            Icon(
              Icons.settings_ethernet,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.systemProxy,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (proxyState.isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Switch(
                value: proxyState.isEnabled,
                onChanged: (_) => _handleToggle(context, ref),
              ),
          ],
        ),

        // 详细信息
        if (showDetails) ...[
          const SizedBox(height: 12),
          _buildDetails(context, l10n, proxyState),
        ],

        // 错误提示
        if (proxyState.errorMessage != null) ...[
          const SizedBox(height: 12),
          _buildError(context, l10n, proxyState.errorMessage!),
        ],
      ],
    );

    if (asCard) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: content,
        ),
      );
    }

    return content;
  }

  /// 构建详细信息
  Widget _buildDetails(
    BuildContext context,
    AppLocalizations l10n,
    SystemProxyState proxyState,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.proxySettings,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            context,
            'HTTP',
            '127.0.0.1:${proxyState.httpPort}',
          ),
          const SizedBox(height: 4),
          _buildDetailRow(
            context,
            'SOCKS',
            '127.0.0.1:${proxyState.socksPort}',
          ),
          const SizedBox(height: 8),
          Text(
            proxyState.isEnabled
                ? l10n.systemProxyEnabled
                : l10n.systemProxyDisabled,
            style: theme.textTheme.bodySmall?.copyWith(
              color: proxyState.isEnabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建详细信息行
  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// 构建错误提示
  Widget _buildError(
    BuildContext context,
    AppLocalizations l10n,
    String errorMessage,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 处理开关切换
  Future<void> _handleToggle(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      await ref.read(systemProxyProvider.notifier).toggleSystemProxy();

      if (context.mounted) {
        final isEnabled = ref.read(systemProxyProvider).isEnabled;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEnabled
                  ? l10n.systemProxyEnabledSuccess
                  : l10n.systemProxyDisabledSuccess,
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(l10n.systemProxyError),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}

/// 简单的系统代理开关（仅开关，无详细信息）
class SimpleSystemProxySwitch extends ConsumerWidget {
  const SimpleSystemProxySwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final proxyState = ref.watch(systemProxyProvider);

    return SwitchListTile(
      title: Text(l10n.systemProxy),
      subtitle: Text(
        proxyState.isEnabled
            ? l10n.systemProxyEnabled
            : l10n.systemProxyDisabled,
      ),
      value: proxyState.isEnabled,
      onChanged: proxyState.isLoading
          ? null
          : (_) async {
              try {
                await ref.read(systemProxyProvider.notifier).toggleSystemProxy();
              } catch (e) {
                // 错误已在 provider 中处理
              }
            },
      secondary: Icon(
        Icons.settings_ethernet,
        color: proxyState.isEnabled
            ? Theme.of(context).colorScheme.primary
            : null,
      ),
    );
  }
}

