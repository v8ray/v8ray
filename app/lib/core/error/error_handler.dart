/// V8Ray 全局错误处理器
///
/// 提供统一的错误处理和日志记录

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/logger.dart';
import 'app_error.dart';

/// 全局错误处理器
class ErrorHandler {
  ErrorHandler._();

  /// 初始化错误处理器
  static void initialize() {
    // 捕获Flutter框架错误
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _logError(
        'Flutter Error',
        details.exception,
        details.stack,
      );
    };

    // 捕获异步错误
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _logError('Async Error', error, stack);
      return true;
    };
  }

  /// 处理错误
  static void handleError(
    Object error, [
    StackTrace? stackTrace,
    BuildContext? context,
  ]) {
    // 记录错误
    _logError('Error', error, stackTrace);

    // 如果有上下文，显示错误提示
    if (context != null && context.mounted) {
      _showErrorSnackBar(context, error);
    }
  }

  /// 处理应用错误
  static void handleAppError(
    AppError error, [
    BuildContext? context,
  ]) {
    // 记录错误
    appLogger.error(
      error.message,
      error.originalError,
      error.stackTrace,
    );

    // 如果有上下文，显示错误提示
    if (context != null && context.mounted) {
      _showAppErrorSnackBar(context, error);
    }
  }

  /// 记录错误
  static void _logError(
    String title,
    Object error,
    StackTrace? stackTrace,
  ) {
    if (error is AppError) {
      appLogger.error(
        '[$title] ${error.message}',
        error.originalError,
        error.stackTrace ?? stackTrace,
      );
    } else {
      appLogger.error(
        '[$title] $error',
        error,
        stackTrace,
      );
    }
  }

  /// 显示错误SnackBar
  static void _showErrorSnackBar(BuildContext context, Object error) {
    final String message = error is AppError ? error.message : error.toString();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onError,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
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

  /// 显示应用错误SnackBar
  static void _showAppErrorSnackBar(BuildContext context, AppError error) {
    if (!context.mounted) return;

    IconData icon = Icons.error_outline;
    if (error is NetworkError) {
      icon = Icons.wifi_off;
    } else if (error is ConfigError) {
      icon = Icons.settings_suggest;
    } else if (error is SubscriptionError) {
      icon = Icons.cloud_off;
    } else if (error is ConnectionError) {
      icon = Icons.link_off;
    } else if (error is PermissionError) {
      icon = Icons.lock;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.onError,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getErrorTitle(error),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    error.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
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

  /// 获取错误标题
  static String _getErrorTitle(AppError error) {
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

  /// 显示错误对话框
  static Future<void> showErrorDialog(
    BuildContext context,
    AppError error, {
    bool showDetails = false,
  }) async {
    if (!context.mounted) return;

    return showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        title: Text(_getErrorTitle(error)),
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
      ),
    );
  }
}

