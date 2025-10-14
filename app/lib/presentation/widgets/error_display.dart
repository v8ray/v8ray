/// V8Ray 错误显示组件
///
/// 提供统一的错误显示UI

import 'package:flutter/material.dart';

import '../../core/error/app_error.dart';

/// 错误显示组件
class ErrorDisplay extends StatelessWidget {
  /// 错误对象
  final AppError error;

  /// 重试回调
  final VoidCallback? onRetry;

  /// 是否显示详细信息
  final bool showDetails;

  const ErrorDisplay({
    required this.error,
    this.onRetry,
    this.showDetails = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 错误图标
            Icon(
              _getErrorIcon(),
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),

            // 错误标题
            Text(
              _getErrorTitle(),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // 错误消息
            Text(
              error.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            // 详细信息
            if (showDetails && error.originalError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  error.originalError.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],

            // 重试按钮
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 获取错误图标
  IconData _getErrorIcon() {
    if (error is NetworkError) {
      return Icons.wifi_off;
    } else if (error is ConfigError) {
      return Icons.settings_suggest;
    } else if (error is SubscriptionError) {
      return Icons.cloud_off;
    } else if (error is ConnectionError) {
      return Icons.link_off;
    } else if (error is PermissionError) {
      return Icons.lock;
    } else {
      return Icons.error_outline;
    }
  }

  /// 获取错误标题
  String _getErrorTitle() {
    if (error is NetworkError) {
      return 'Network Error';
    } else if (error is ConfigError) {
      return 'Configuration Error';
    } else if (error is SubscriptionError) {
      return 'Subscription Error';
    } else if (error is ConnectionError) {
      return 'Connection Error';
    } else if (error is PermissionError) {
      return 'Permission Error';
    } else {
      return 'Error';
    }
  }
}

/// 错误对话框
class ErrorDialog extends StatelessWidget {
  /// 错误对象
  final AppError error;

  /// 是否显示详细信息
  final bool showDetails;

  const ErrorDialog({required this.error, this.showDetails = false, super.key});

  /// 显示错误对话框
  static Future<void> show(
    BuildContext context,
    AppError error, {
    bool showDetails = false,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(error: error, showDetails: showDetails),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        Icons.error_outline,
        color: Theme.of(context).colorScheme.error,
        size: 48,
      ),
      title: const Text('Error'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(error.message),
          if (showDetails && error.originalError != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Details:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                error.originalError.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

/// 错误SnackBar
class ErrorSnackBar {
  ErrorSnackBar._();

  /// 显示错误SnackBar
  static void show(BuildContext context, AppError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onError,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(error.message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
