/// V8Ray 页面切换动画
///
/// 提供各种页面切换动画效果

import 'package:flutter/material.dart';

/// 页面切换动画类型
enum PageTransitionType {
  /// 淡入淡出
  fade,

  /// 从右滑入
  slideRight,

  /// 从左滑入
  slideLeft,

  /// 从下滑入
  slideUp,

  /// 缩放
  scale,

  /// 旋转
  rotate,

  /// 淡入+缩放
  fadeScale,
}

/// 自定义页面路由（带动画）
class AnimatedPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final PageTransitionType transitionType;
  final Duration duration;
  final Curve curve;

  AnimatedPageRoute({
    required this.page,
    this.transitionType = PageTransitionType.slideRight,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    RouteSettings? settings,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         settings: settings,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return _buildTransition(
             child,
             animation,
             secondaryAnimation,
             transitionType,
             curve,
           );
         },
       );

  static Widget _buildTransition(
    Widget child,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    PageTransitionType type,
    Curve curve,
  ) {
    final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);

    switch (type) {
      case PageTransitionType.fade:
        return FadeTransition(opacity: curvedAnimation, child: child);

      case PageTransitionType.slideRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case PageTransitionType.slideLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case PageTransitionType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case PageTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
          child: child,
        );

      case PageTransitionType.rotate:
        return RotationTransition(
          turns: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(opacity: curvedAnimation, child: child),
        );

      case PageTransitionType.fadeScale:
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
    }
  }
}

/// 共享元素过渡动画
class SharedAxisTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final SharedAxisTransitionType transitionType;

  const SharedAxisTransition({
    required this.child,
    required this.animation,
    this.transitionType = SharedAxisTransitionType.horizontal,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );

    final slideAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    Offset getBeginOffset() {
      switch (transitionType) {
        case SharedAxisTransitionType.horizontal:
          return const Offset(0.3, 0.0);
        case SharedAxisTransitionType.vertical:
          return const Offset(0.0, 0.3);
        case SharedAxisTransitionType.scaled:
          return Offset.zero;
      }
    }

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: getBeginOffset(),
          end: Offset.zero,
        ).animate(slideAnimation),
        child: child,
      ),
    );
  }
}

enum SharedAxisTransitionType { horizontal, vertical, scaled }

/// 页面切换动画包装器
class PageTransitionSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final PageTransitionType transitionType;

  const PageTransitionSwitcher({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.transitionType = PageTransitionType.fadeScale,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        return AnimatedPageRoute._buildTransition(
          child,
          animation,
          const AlwaysStoppedAnimation(0.0),
          transitionType,
          Curves.easeInOut,
        );
      },
      child: child,
    );
  }
}

/// 列表项动画
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;

  const AnimatedListItem({
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 300),
    super.key,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // 延迟启动动画
    Future.delayed(widget.delay * widget.index, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
