/// V8Ray 连接状态动画组件
///
/// 提供连接状态的各种动画效果

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 波纹扩散动画
class RippleAnimation extends StatefulWidget {
  final Color color;
  final double size;
  final int rippleCount;

  const RippleAnimation({
    required this.color,
    this.size = 120,
    this.rippleCount = 3,
    super.key,
  });

  @override
  State<RippleAnimation> createState() => _RippleAnimationState();
}

class _RippleAnimationState extends State<RippleAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.rippleCount,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 2000),
        vsync: this,
      ),
    );

    _animations =
        _controllers.map((controller) {
          return Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
        }).toList();

    // 错开启动每个波纹
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 600), () {
        if (mounted) {
          _controllers[i].repeat();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children:
            _animations.map((animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Container(
                    width: widget.size * animation.value,
                    height: widget.size * animation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.color.withOpacity(1.0 - animation.value),
                        width: 2.0,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
      ),
    );
  }
}

/// 旋转光环动画
class RotatingRingAnimation extends StatefulWidget {
  final Color color;
  final double size;
  final double strokeWidth;

  const RotatingRingAnimation({
    required this.color,
    this.size = 120,
    this.strokeWidth = 3.0,
    super.key,
  });

  @override
  State<RotatingRingAnimation> createState() => _RotatingRingAnimationState();
}

class _RotatingRingAnimationState extends State<RotatingRingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _RingPainter(
              color: widget.color,
              strokeWidth: widget.strokeWidth,
              progress: _controller.value,
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double progress;

  _RingPainter({
    required this.color,
    required this.strokeWidth,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 绘制部分圆弧
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 1.5,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => true;
}

/// 数据流动画
class DataFlowAnimation extends StatefulWidget {
  final Color color;
  final double size;
  final bool isUpload;

  const DataFlowAnimation({
    required this.color,
    this.size = 40,
    this.isUpload = true,
    super.key,
  });

  @override
  State<DataFlowAnimation> createState() => _DataFlowAnimationState();
}

class _DataFlowAnimationState extends State<DataFlowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _DataFlowPainter(
            color: widget.color,
            progress: _animation.value,
            isUpload: widget.isUpload,
          ),
        );
      },
    );
  }
}

class _DataFlowPainter extends CustomPainter {
  final Color color;
  final double progress;
  final bool isUpload;

  _DataFlowPainter({
    required this.color,
    required this.progress,
    required this.isUpload,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final dotCount = 3;
    final spacing = size.height / (dotCount + 1);

    for (int i = 0; i < dotCount; i++) {
      final offset = (progress + i / dotCount) % 1.0;
      final y =
          isUpload
              ? size.height - (offset * size.height)
              : offset * size.height;

      final opacity = 1.0 - (offset * 0.7);
      paint.color = color.withOpacity(opacity);

      canvas.drawCircle(Offset(size.width / 2, y), 3.0, paint);
    }
  }

  @override
  bool shouldRepaint(_DataFlowPainter oldDelegate) => true;
}

/// 成功动画（打勾）
class SuccessAnimation extends StatefulWidget {
  final Color color;
  final double size;

  const SuccessAnimation({required this.color, this.size = 60, super.key});

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _CheckMarkPainter(
            color: widget.color,
            progress: _animation.value,
          ),
        );
      },
    );
  }
}

class _CheckMarkPainter extends CustomPainter {
  final Color color;
  final double progress;

  _CheckMarkPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 4.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final path = Path();
    final checkSize = size.width * 0.6;
    final startX = size.width * 0.2;
    final startY = size.height * 0.5;

    // 第一段（向下）
    if (progress < 0.5) {
      final p = progress * 2;
      path.moveTo(startX, startY);
      path.lineTo(startX + checkSize * 0.3 * p, startY + checkSize * 0.3 * p);
    } else {
      // 第二段（向上）
      final p = (progress - 0.5) * 2;
      path.moveTo(startX, startY);
      path.lineTo(startX + checkSize * 0.3, startY + checkSize * 0.3);
      path.lineTo(
        startX + checkSize * 0.3 + checkSize * 0.7 * p,
        startY + checkSize * 0.3 - checkSize * 0.6 * p,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckMarkPainter oldDelegate) => true;
}
