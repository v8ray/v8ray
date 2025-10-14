/// V8Ray 错误消息
///
/// 提供用户友好的错误消息

import '../l10n/app_localizations.dart';
import 'app_error.dart';

/// 错误消息工具类
class ErrorMessages {
  ErrorMessages._();

  /// 获取用户友好的错误消息
  static String getUserFriendlyMessage(
    AppLocalizations l10n,
    Object error,
  ) {
    if (error is AppError) {
      return _getAppErrorMessage(l10n, error);
    }

    // 通用错误消息
    return l10n.unknownError;
  }

  /// 获取应用错误消息
  static String _getAppErrorMessage(
    AppLocalizations l10n,
    AppError error,
  ) {
    if (error is NetworkError) {
      return _getNetworkErrorMessage(l10n, error);
    } else if (error is SubscriptionError) {
      return _getSubscriptionErrorMessage(l10n, error);
    } else if (error is ConnectionError) {
      return _getConnectionErrorMessage(l10n, error);
    } else if (error is ConfigError) {
      return _getConfigErrorMessage(l10n, error);
    } else if (error is PermissionError) {
      return _getPermissionErrorMessage(l10n, error);
    }

    return error.message;
  }

  /// 获取网络错误消息
  static String _getNetworkErrorMessage(
    AppLocalizations l10n,
    NetworkError error,
  ) {
    final message = error.message.toLowerCase();

    if (message.contains('timeout')) {
      return l10n.networkTimeoutError;
    } else if (message.contains('dns') || message.contains('resolve')) {
      return l10n.dnsResolutionError;
    } else if (message.contains('connection refused')) {
      return l10n.connectionRefusedError;
    } else if (message.contains('no internet') || 
               message.contains('network unavailable')) {
      return l10n.noInternetError;
    } else if (message.contains('ssl') || message.contains('certificate')) {
      return l10n.sslCertificateError;
    }

    return '${l10n.networkError}: ${error.message}';
  }

  /// 获取订阅错误消息
  static String _getSubscriptionErrorMessage(
    AppLocalizations l10n,
    SubscriptionError error,
  ) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid url') || message.contains('url')) {
      return l10n.invalidSubscriptionUrl;
    } else if (message.contains('parse') || message.contains('decode')) {
      return l10n.subscriptionParseError;
    } else if (message.contains('empty') || message.contains('no servers')) {
      return l10n.emptySubscriptionError;
    } else if (message.contains('not found') || message.contains('404')) {
      return l10n.subscriptionNotFoundError;
    } else if (message.contains('unauthorized') || message.contains('401')) {
      return l10n.subscriptionUnauthorizedError;
    }

    return '${l10n.subscriptionError}: ${error.message}';
  }

  /// 获取连接错误消息
  static String _getConnectionErrorMessage(
    AppLocalizations l10n,
    ConnectionError error,
  ) {
    final message = error.message.toLowerCase();

    if (message.contains('timeout')) {
      return l10n.connectionTimeoutError;
    } else if (message.contains('refused')) {
      return l10n.connectionRefusedError;
    } else if (message.contains('no server selected')) {
      return l10n.noServerSelectedError;
    } else if (message.contains('already connected')) {
      return l10n.alreadyConnectedError;
    } else if (message.contains('not connected')) {
      return l10n.notConnectedError;
    }

    return '${l10n.connectionError}: ${error.message}';
  }

  /// 获取配置错误消息
  static String _getConfigErrorMessage(
    AppLocalizations l10n,
    ConfigError error,
  ) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid')) {
      return l10n.invalidConfigError;
    } else if (message.contains('missing')) {
      return l10n.missingConfigError;
    }

    return '${l10n.configError}: ${error.message}';
  }

  /// 获取权限错误消息
  static String _getPermissionErrorMessage(
    AppLocalizations l10n,
    PermissionError error,
  ) {
    final message = error.message.toLowerCase();

    if (message.contains('vpn')) {
      return l10n.vpnPermissionError;
    } else if (message.contains('network')) {
      return l10n.networkPermissionError;
    } else if (message.contains('storage')) {
      return l10n.storagePermissionError;
    }

    return '${l10n.permissionError}: ${error.message}';
  }

  /// 获取错误建议
  static String? getErrorSuggestion(
    AppLocalizations l10n,
    Object error,
  ) {
    if (error is NetworkError) {
      return l10n.networkErrorSuggestion;
    } else if (error is SubscriptionError) {
      return l10n.subscriptionErrorSuggestion;
    } else if (error is ConnectionError) {
      return l10n.connectionErrorSuggestion;
    } else if (error is PermissionError) {
      return l10n.permissionErrorSuggestion;
    }

    return null;
  }
}

