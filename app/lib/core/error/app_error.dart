/// V8Ray 应用错误定义
///
/// 定义应用中使用的所有错误类型

/// 应用错误基类
abstract class AppError implements Exception {
  /// 错误消息
  final String message;

  /// 错误代码
  final String? code;

  /// 原始错误
  final dynamic originalError;

  /// 堆栈跟踪
  final StackTrace? stackTrace;

  const AppError({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('$runtimeType: $message');
    if (code != null) {
      buffer.write(' (code: $code)');
    }
    if (originalError != null) {
      buffer.write('\nOriginal error: $originalError');
    }
    return buffer.toString();
  }
}

/// 网络错误
class NetworkError extends AppError {
  const NetworkError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  /// 创建连接超时错误
  factory NetworkError.timeout() {
    return const NetworkError(
      message: 'Connection timeout',
      code: 'NETWORK_TIMEOUT',
    );
  }

  /// 创建无网络连接错误
  factory NetworkError.noConnection() {
    return const NetworkError(
      message: 'No internet connection',
      code: 'NO_CONNECTION',
    );
  }

  /// 创建请求失败错误
  factory NetworkError.requestFailed(dynamic error) {
    return NetworkError(
      message: 'Request failed',
      code: 'REQUEST_FAILED',
      originalError: error,
    );
  }
}

/// 配置错误
class ConfigError extends AppError {
  const ConfigError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  /// 创建无效配置错误
  factory ConfigError.invalid(String reason) {
    return ConfigError(
      message: 'Invalid configuration: $reason',
      code: 'INVALID_CONFIG',
    );
  }

  /// 创建配置加载失败错误
  factory ConfigError.loadFailed(dynamic error) {
    return ConfigError(
      message: 'Failed to load configuration',
      code: 'LOAD_FAILED',
      originalError: error,
    );
  }

  /// 创建配置保存失败错误
  factory ConfigError.saveFailed(dynamic error) {
    return ConfigError(
      message: 'Failed to save configuration',
      code: 'SAVE_FAILED',
      originalError: error,
    );
  }
}

/// 订阅错误
class SubscriptionError extends AppError {
  const SubscriptionError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  /// 创建无效URL错误
  factory SubscriptionError.invalidUrl() {
    return const SubscriptionError(
      message: 'Invalid subscription URL',
      code: 'INVALID_URL',
    );
  }

  /// 创建解析失败错误
  factory SubscriptionError.parseFailed(dynamic error) {
    return SubscriptionError(
      message: 'Failed to parse subscription',
      code: 'PARSE_FAILED',
      originalError: error,
    );
  }

  /// 创建更新失败错误
  factory SubscriptionError.updateFailed(dynamic error) {
    return SubscriptionError(
      message: 'Failed to update subscription',
      code: 'UPDATE_FAILED',
      originalError: error,
    );
  }

  /// 创建空订阅错误
  factory SubscriptionError.empty() {
    return const SubscriptionError(
      message: 'Subscription is empty',
      code: 'EMPTY_SUBSCRIPTION',
    );
  }
}

/// 连接错误
class ConnectionError extends AppError {
  const ConnectionError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  /// 创建连接失败错误
  factory ConnectionError.failed(dynamic error) {
    return ConnectionError(
      message: 'Connection failed',
      code: 'CONNECTION_FAILED',
      originalError: error,
    );
  }

  /// 创建无可用节点错误
  factory ConnectionError.noAvailableNode() {
    return const ConnectionError(
      message: 'No available node',
      code: 'NO_AVAILABLE_NODE',
    );
  }

  /// 创建代理启动失败错误
  factory ConnectionError.proxyStartFailed(dynamic error) {
    return ConnectionError(
      message: 'Failed to start proxy',
      code: 'PROXY_START_FAILED',
      originalError: error,
    );
  }

  /// 创建代理停止失败错误
  factory ConnectionError.proxyStopFailed(dynamic error) {
    return ConnectionError(
      message: 'Failed to stop proxy',
      code: 'PROXY_STOP_FAILED',
      originalError: error,
    );
  }
}

/// 存储错误
class StorageError extends AppError {
  const StorageError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  /// 创建读取失败错误
  factory StorageError.readFailed(dynamic error) {
    return StorageError(
      message: 'Failed to read from storage',
      code: 'READ_FAILED',
      originalError: error,
    );
  }

  /// 创建写入失败错误
  factory StorageError.writeFailed(dynamic error) {
    return StorageError(
      message: 'Failed to write to storage',
      code: 'WRITE_FAILED',
      originalError: error,
    );
  }

  /// 创建删除失败错误
  factory StorageError.deleteFailed(dynamic error) {
    return StorageError(
      message: 'Failed to delete from storage',
      code: 'DELETE_FAILED',
      originalError: error,
    );
  }
}

/// 权限错误
class PermissionError extends AppError {
  const PermissionError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  /// 创建权限被拒绝错误
  factory PermissionError.denied(String permission) {
    return PermissionError(
      message: 'Permission denied: $permission',
      code: 'PERMISSION_DENIED',
    );
  }

  /// 创建需要VPN权限错误
  factory PermissionError.vpnRequired() {
    return const PermissionError(
      message: 'VPN permission required',
      code: 'VPN_PERMISSION_REQUIRED',
    );
  }
}

/// 未知错误
class UnknownError extends AppError {
  const UnknownError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  /// 从任意错误创建
  factory UnknownError.from(dynamic error, [StackTrace? stackTrace]) {
    return UnknownError(
      message: error.toString(),
      code: 'UNKNOWN',
      originalError: error,
      stackTrace: stackTrace,
    );
  }
}
