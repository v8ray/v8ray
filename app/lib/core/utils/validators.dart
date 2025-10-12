/// V8Ray 验证工具
///
/// 提供各种输入验证功能

import '../constants/app_constants.dart';

/// 验证工具类
class Validators {
  Validators._();

  /// 验证订阅URL
  static bool isValidSubscriptionUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }

    final urlRegex = RegExp(SubscriptionConstants.urlPattern);
    return urlRegex.hasMatch(url);
  }

  /// 验证端口号
  static bool isValidPort(String? port) {
    if (port == null || port.isEmpty) {
      return false;
    }

    final portNumber = int.tryParse(port);
    if (portNumber == null) {
      return false;
    }

    return portNumber >= 1 && portNumber <= 65535;
  }

  /// 验证IP地址
  static bool isValidIpAddress(String? ip) {
    if (ip == null || ip.isEmpty) {
      return false;
    }

    final ipRegex = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    return ipRegex.hasMatch(ip);
  }

  /// 验证域名
  static bool isValidDomain(String? domain) {
    if (domain == null || domain.isEmpty) {
      return false;
    }

    final domainRegex = RegExp(
      r'^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$',
    );
    return domainRegex.hasMatch(domain);
  }

  /// 验证非空字符串
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// 验证邮箱
  static bool isValidEmail(String? email) {
    if (email == null || email.isEmpty) {
      return false;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
