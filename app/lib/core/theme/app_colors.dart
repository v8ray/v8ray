/// V8Ray 应用颜色定义
///
/// 定义应用中使用的特殊颜色

import 'package:flutter/material.dart';

/// 应用颜色
class AppColors {
  AppColors._();

  // 连接状态颜色
  /// 已连接 - 绿色
  static const Color connected = Color(0xFF4CAF50);

  /// 连接中 - 橙色
  static const Color connecting = Color(0xFFFF9800);

  /// 未连接 - 红色
  static const Color disconnected = Color(0xFFF44336);

  /// 错误 - 红色
  static const Color error = Color(0xFFF44336);

  // 功能色
  /// 成功
  static const Color success = Color(0xFF4CAF50);

  /// 警告
  static const Color warning = Color(0xFFFF9800);

  /// 信息
  static const Color info = Color(0xFF2196F3);

  // 速度指示颜色
  /// 快速 (< 100ms)
  static const Color speedFast = Color(0xFF4CAF50);

  /// 中等 (100-300ms)
  static const Color speedMedium = Color(0xFFFF9800);

  /// 慢速 (> 300ms)
  static const Color speedSlow = Color(0xFFF44336);

  /// 超时
  static const Color speedTimeout = Color(0xFF9E9E9E);

  /// 根据延迟获取颜色
  static Color getLatencyColor(int? latency) {
    if (latency == null || latency < 0) {
      return speedTimeout;
    } else if (latency < 100) {
      return speedFast;
    } else if (latency < 300) {
      return speedMedium;
    } else {
      return speedSlow;
    }
  }

  /// 根据连接状态获取颜色
  static Color getConnectionStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'connected':
        return connected;
      case 'connecting':
        return connecting;
      case 'disconnected':
        return disconnected;
      case 'error':
        return error;
      default:
        return disconnected;
    }
  }
}
