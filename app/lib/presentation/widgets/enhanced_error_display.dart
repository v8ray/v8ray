/// V8Ray 增强错误显示组件
///
/// 提供带重试功能的错误显示

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/error/app_error.dart';
import '../../core/error/error_messages.dart';
import '../../core/l10n/app_localizations.dart';

/// 增强错误显示组件
class EnhancedErrorDisplay extends StatelessWidget {
  /// 错误对象
  final Object error;

  /// 重试回调
  final VoidCallback? onRetry;

  /// 是否显示详细信息
  final bool showDetails;

  /// 图标大小
  final double iconSize;

  const EnhancedErrorDisplay({
    required this.error,
    this.onRetry,
    this.showDetails = false,
    this.iconSize = 48,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final message =
        error is AppError
            ? ErrorMessages.getUserFriendlyMessage(l10n, error)
            : error.toString();

    final suggestion =
        error is AppError
            ? ErrorMessages.getErrorSuggestion(l10n, error)
            : null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 错误图标
            Icon(
              Icons.error_outline,
              size: iconSize,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),

            // 错误消息
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            // 建议
            if (suggestion != null) ...[
              const SizedBox(height: 12),
              Text(
                suggestion,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // 详细信息
            if (showDetails && error is AppError) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  (error as AppError).originalError?.toString() ??
                      error.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onErrorContainer,
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
                label: Text(l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 带自动重试的错误显示组件
class AutoRetryErrorDisplay extends StatefulWidget {
  /// 错误对象
  final Object error;

  /// 重试回调
  final Future<void> Function() onRetry;

  /// 最大重试次数
  final int maxRetries;

  /// 重试延迟（秒）
  final int retryDelay;

  /// 是否自动重试
  final bool autoRetry;

  const AutoRetryErrorDisplay({
    required this.error,
    required this.onRetry,
    this.maxRetries = 3,
    this.retryDelay = 5,
    this.autoRetry = false,
    super.key,
  });

  @override
  State<AutoRetryErrorDisplay> createState() => _AutoRetryErrorDisplayState();
}

class _AutoRetryErrorDisplayState extends State<AutoRetryErrorDisplay> {
  int _retryCount = 0;
  int _countdown = 0;
  Timer? _countdownTimer;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoRetry && _retryCount < widget.maxRetries) {
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _countdown = widget.retryDelay;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _handleRetry();
      }
    });
  }

  Future<void> _handleRetry() async {
    if (_isRetrying) return;

    setState(() {
      _isRetrying = true;
      _retryCount++;
    });

    try {
      await widget.onRetry();
    } catch (e) {
      // 错误会在父组件处理
      if (mounted && _retryCount < widget.maxRetries && widget.autoRetry) {
        _startCountdown();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final message =
        widget.error is AppError
            ? ErrorMessages.getUserFriendlyMessage(l10n, widget.error)
            : widget.error.toString();

    final suggestion =
        widget.error is AppError
            ? ErrorMessages.getErrorSuggestion(l10n, widget.error)
            : null;

    final canRetry = _retryCount < widget.maxRetries;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 错误图标
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),

            // 错误消息
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            // 建议
            if (suggestion != null) ...[
              const SizedBox(height: 12),
              Text(
                suggestion,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            // 重试状态
            if (_isRetrying)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(l10n.retrying, style: theme.textTheme.bodyMedium),
                ],
              )
            else if (_countdown > 0)
              Column(
                children: [
                  Text(
                    l10n.retryIn(_countdown),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: 1 - (_countdown / widget.retryDelay),
                  ),
                ],
              )
            else if (canRetry)
              FilledButton.icon(
                onPressed: _handleRetry,
                icon: const Icon(Icons.refresh),
                label: Text(
                  '${l10n.retry} (${_retryCount}/${widget.maxRetries})',
                ),
              )
            else
              Text(
                'Max retries reached',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
