/// V8Ray 应用常量定义
///
/// 定义应用中使用的所有常量，包括应用信息、配置参数等

/// 应用信息
class AppInfo {
  AppInfo._();

  /// 应用名称
  static const String appName = 'V8Ray';

  /// 应用版本
  static const String version = '0.1.0';

  /// 构建号
  static const int buildNumber = 1;

  /// 应用描述
  static const String description =
      'Cross-platform Xray Core client built with Flutter and Rust';

  /// 开发者
  static const String developer = 'V8Ray Team';

  /// 项目主页
  static const String homepage = 'https://github.com/yourusername/v8ray';

  /// 问题反馈
  static const String issuesUrl =
      'https://github.com/yourusername/v8ray/issues';
}

/// 存储键名
class StorageKeys {
  StorageKeys._();

  /// 语言代码
  static const String languageCode = 'language_code';

  /// 主题模式
  static const String themeMode = 'theme_mode';

  /// 是否首次启动
  static const String isFirstLaunch = 'is_first_launch';

  /// 上次使用的订阅URL
  static const String lastSubscriptionUrl = 'last_subscription_url';

  /// 上次使用的代理模式
  static const String lastProxyMode = 'last_proxy_mode';

  /// 上次使用的节点ID
  static const String lastNodeId = 'last_node_id';

  /// 自动连接
  static const String autoConnect = 'auto_connect';

  /// 开机启动
  static const String startOnBoot = 'start_on_boot';
}

/// 路由路径
class RoutePaths {
  RoutePaths._();

  /// 简单模式主页
  static const String simpleHome = '/simple';

  /// 高级模式主页
  static const String advancedHome = '/advanced';

  /// 设置页面
  static const String settings = '/settings';

  /// 关于页面
  static const String about = '/about';

  /// 订阅管理
  static const String subscriptions = '/subscriptions';

  /// 节点管理
  static const String nodes = '/nodes';

  /// 日志查看
  static const String logs = '/logs';
}

/// UI常量
class UIConstants {
  UIConstants._();

  /// 默认内边距
  static const double defaultPadding = 16.0;

  /// 小内边距
  static const double smallPadding = 8.0;

  /// 大内边距
  static const double largePadding = 24.0;

  /// 卡片圆角
  static const double cardBorderRadius = 12.0;

  /// 按钮圆角
  static const double buttonBorderRadius = 20.0;

  /// 按钮最小高度
  static const double buttonMinHeight = 48.0;

  /// 输入框高度
  static const double inputHeight = 56.0;

  /// 图标大小
  static const double iconSize = 24.0;

  /// 大图标大小
  static const double largeIconSize = 48.0;

  /// 动画时长（毫秒）
  static const int animationDuration = 300;

  /// 快速动画时长（毫秒）
  static const int fastAnimationDuration = 150;
}

/// 代理模式
enum ProxyMode {
  /// 全局模式
  global,

  /// 智能分流
  smart,

  /// 直连模式
  direct,
}

/// 连接状态
enum ConnectionStatus {
  /// 未连接
  disconnected,

  /// 连接中
  connecting,

  /// 已连接
  connected,

  /// 断开中
  disconnecting,

  /// 错误
  error,
}

/// 主题模式
enum AppThemeMode {
  /// 浅色
  light,

  /// 深色
  dark,

  /// 跟随系统
  system,
}

/// 日志级别
enum LogLevel {
  /// 调试
  debug,

  /// 信息
  info,

  /// 警告
  warning,

  /// 错误
  error,
}

/// 网络常量
class NetworkConstants {
  NetworkConstants._();

  /// 默认超时时间（秒）
  static const int defaultTimeout = 30;

  /// 连接超时时间（秒）
  static const int connectTimeout = 10;

  /// 接收超时时间（秒）
  static const int receiveTimeout = 30;

  /// 最大重试次数
  static const int maxRetries = 3;
}

/// 订阅常量
class SubscriptionConstants {
  SubscriptionConstants._();

  /// 自动更新间隔（小时）
  static const int autoUpdateInterval = 6;

  /// 最大节点数
  static const int maxNodes = 1000;

  /// 订阅URL正则表达式
  static const String urlPattern =
      r'^https?://[a-zA-Z0-9\-._~:/?#\[\]@!$&()*+,;=%]+$';
}
