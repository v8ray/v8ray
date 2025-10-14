/// V8Ray 用户引导提示组件
///
/// 提供首次使用引导和操作提示

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户引导提示组件
class UserGuideTooltip extends StatefulWidget {
  /// 引导键（用于标识是否已显示过）
  final String guideKey;

  /// 提示消息
  final String message;

  /// 子组件
  final Widget child;

  /// 提示位置
  final TooltipPosition position;

  /// 是否只显示一次
  final bool showOnce;

  /// 延迟显示时间（毫秒）
  final int delayMs;

  const UserGuideTooltip({
    required this.guideKey,
    required this.message,
    required this.child,
    this.position = TooltipPosition.bottom,
    this.showOnce = true,
    this.delayMs = 500,
    super.key,
  });

  @override
  State<UserGuideTooltip> createState() => _UserGuideTooltipState();
}

class _UserGuideTooltipState extends State<UserGuideTooltip> {
  bool _shouldShow = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _checkShouldShow();
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  Future<void> _checkShouldShow() async {
    if (!widget.showOnce) {
      setState(() {
        _shouldShow = true;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool('guide_${widget.guideKey}') ?? false;

    if (!hasShown) {
      setState(() {
        _shouldShow = true;
      });

      // 延迟显示
      await Future.delayed(Duration(milliseconds: widget.delayMs));
      if (mounted) {
        _showOverlay();
      }
    }
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder:
          (context) => _TooltipOverlay(
            message: widget.message,
            targetOffset: offset,
            targetSize: size,
            position: widget.position,
            onDismiss: _dismissTooltip,
          ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _dismissTooltip() async {
    _removeOverlay();

    if (widget.showOnce) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('guide_${widget.guideKey}', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// 提示位置
enum TooltipPosition { top, bottom, left, right }

/// 提示遮罩层
class _TooltipOverlay extends StatelessWidget {
  final String message;
  final Offset targetOffset;
  final Size targetSize;
  final TooltipPosition position;
  final VoidCallback onDismiss;

  const _TooltipOverlay({
    required this.message,
    required this.targetOffset,
    required this.targetSize,
    required this.position,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Material(
        color: Colors.black54,
        child: Stack(
          children: [
            // 高亮目标区域
            Positioned(
              left: targetOffset.dx - 4,
              top: targetOffset.dy - 4,
              child: Container(
                width: targetSize.width + 8,
                height: targetSize.height + 8,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            ),

            // 提示气泡
            Positioned(
              left: _calculateLeft(),
              top: _calculateTop(),
              child: _TooltipBubble(message: message, onDismiss: onDismiss),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateLeft() {
    switch (position) {
      case TooltipPosition.left:
        return targetOffset.dx - 220;
      case TooltipPosition.right:
        return targetOffset.dx + targetSize.width + 12;
      default:
        return targetOffset.dx;
    }
  }

  double _calculateTop() {
    switch (position) {
      case TooltipPosition.top:
        return targetOffset.dy - 100;
      case TooltipPosition.bottom:
        return targetOffset.dy + targetSize.height + 12;
      default:
        return targetOffset.dy;
    }
  }
}

/// 提示气泡
class _TooltipBubble extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _TooltipBubble({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onDismiss,
              child: Text(
                'Got it',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 简单提示组件
class SimpleTooltip extends StatelessWidget {
  final String message;
  final Widget child;
  final bool enabled;

  const SimpleTooltip({
    required this.message,
    required this.child,
    this.enabled = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Tooltip(
      message: message,
      preferBelow: true,
      verticalOffset: 12,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: TextStyle(
        color: Theme.of(context).colorScheme.onInverseSurface,
        fontSize: 14,
      ),
      child: child,
    );
  }
}
