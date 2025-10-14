/// V8Ray 动画按钮组件
///
/// 提供增强的按钮交互反馈

import 'package:flutter/material.dart';

/// 动画按钮样式
enum AnimatedButtonStyle {
  /// 主要按钮
  primary,

  /// 次要按钮
  secondary,

  /// 文本按钮
  text,

  /// 轮廓按钮
  outlined,
}

/// 动画按钮组件
class AnimatedButton extends StatefulWidget {
  /// 按钮文本
  final String text;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 按钮样式
  final AnimatedButtonStyle style;

  /// 图标
  final IconData? icon;

  /// 是否加载中
  final bool isLoading;

  /// 是否全宽
  final bool fullWidth;

  /// 最小高度
  final double? minHeight;

  const AnimatedButton({
    required this.text,
    this.onPressed,
    this.style = AnimatedButtonStyle.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.minHeight,
    super.key,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.fullWidth ? double.infinity : null,
          height: widget.minHeight ?? 48,
          child: _buildButton(context, theme, isDisabled),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, ThemeData theme, bool isDisabled) {
    switch (widget.style) {
      case AnimatedButtonStyle.primary:
        return ElevatedButton(
          onPressed: isDisabled ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(widget.fullWidth ? double.infinity : 120, widget.minHeight ?? 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: _buildButtonContent(theme),
        );

      case AnimatedButtonStyle.secondary:
        return FilledButton.tonal(
          onPressed: isDisabled ? null : widget.onPressed,
          style: FilledButton.styleFrom(
            minimumSize: Size(widget.fullWidth ? double.infinity : 120, widget.minHeight ?? 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: _buildButtonContent(theme),
        );

      case AnimatedButtonStyle.outlined:
        return OutlinedButton(
          onPressed: isDisabled ? null : widget.onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(widget.fullWidth ? double.infinity : 120, widget.minHeight ?? 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: _buildButtonContent(theme),
        );

      case AnimatedButtonStyle.text:
        return TextButton(
          onPressed: isDisabled ? null : widget.onPressed,
          style: TextButton.styleFrom(
            minimumSize: Size(widget.fullWidth ? double.infinity : 120, widget.minHeight ?? 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: _buildButtonContent(theme),
        );
    }
  }

  Widget _buildButtonContent(ThemeData theme) {
    if (widget.isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 20),
          const SizedBox(width: 8),
          Text(widget.text),
        ],
      );
    }

    return Text(widget.text);
  }
}

/// 浮动操作按钮（带动画）
class AnimatedFAB extends StatefulWidget {
  /// 图标
  final IconData icon;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 提示文本
  final String? tooltip;

  /// 是否扩展显示文本
  final bool extended;

  /// 扩展文本
  final String? label;

  const AnimatedFAB({
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.extended = false,
    this.label,
    super.key,
  });

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: RotationTransition(
        turns: _rotationAnimation,
        child: widget.extended && widget.label != null
            ? FloatingActionButton.extended(
                onPressed: widget.onPressed != null ? _handleTap : null,
                icon: Icon(widget.icon),
                label: Text(widget.label!),
                tooltip: widget.tooltip,
              )
            : FloatingActionButton(
                onPressed: widget.onPressed != null ? _handleTap : null,
                tooltip: widget.tooltip,
                child: Icon(widget.icon),
              ),
      ),
    );
  }
}

