/// V8Ray 加载遮罩组件
///
/// 提供全屏和局部加载指示器

import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';

/// 加载遮罩组件
class LoadingOverlay extends StatelessWidget {
  /// 是否显示加载遮罩
  final bool isLoading;

  /// 子组件
  final Widget child;

  /// 加载消息
  final String? message;

  /// 是否可取消
  final bool cancelable;

  /// 取消回调
  final VoidCallback? onCancel;

  const LoadingOverlay({
    required this.isLoading,
    required this.child,
    this.message,
    this.cancelable = false,
    this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: LoadingIndicator(
                  message: message,
                  cancelable: cancelable,
                  onCancel: onCancel,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 加载指示器组件
class LoadingIndicator extends StatelessWidget {
  /// 加载消息
  final String? message;

  /// 是否可取消
  final bool cancelable;

  /// 取消回调
  final VoidCallback? onCancel;

  /// 大小
  final double size;

  const LoadingIndicator({
    this.message,
    this.cancelable = false,
    this.onCancel,
    this.size = 48,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: const CircularProgressIndicator(),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
            if (cancelable && onCancel != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onCancel,
                child: Text(l10n?.cancel ?? 'Cancel'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 内联加载指示器
class InlineLoadingIndicator extends StatelessWidget {
  /// 加载消息
  final String? message;

  /// 大小
  final double size;

  const InlineLoadingIndicator({
    this.message,
    this.size = 24,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        if (message != null) ...[
          const SizedBox(width: 12),
          Text(
            message!,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}

/// 骨架屏加载器
class SkeletonLoader extends StatefulWidget {
  /// 宽度
  final double? width;

  /// 高度
  final double height;

  /// 圆角
  final double borderRadius;

  const SkeletonLoader({
    this.width,
    this.height = 16,
    this.borderRadius = 4,
    super.key,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isDark
                  ? [
                      Colors.grey[800]!,
                      Colors.grey[700]!,
                      Colors.grey[800]!,
                    ]
                  : [
                      Colors.grey[300]!,
                      Colors.grey[200]!,
                      Colors.grey[300]!,
                    ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// 列表骨架加载器
class ListSkeletonLoader extends StatelessWidget {
  /// 项目数量
  final int itemCount;

  /// 项目高度
  final double itemHeight;

  /// 间距
  final double spacing;

  const ListSkeletonLoader({
    this.itemCount = 3,
    this.itemHeight = 80,
    this.spacing = 12,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (context, index) => SizedBox(height: spacing),
      itemBuilder: (context, index) {
        return SkeletonLoader(
          height: itemHeight,
          borderRadius: 8,
        );
      },
    );
  }
}

