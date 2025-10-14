// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'V8Ray';

  @override
  String get errorAdminPrivilegesRequired => '需要管理员权限';

  @override
  String get errorAdminPrivilegesMessage =>
      'V8Ray 需要管理员/root 权限来管理系统代理设置。\n\n请使用管理员权限运行应用程序：\n• Linux/macOS: sudo ./v8ray\n• Windows: 右键点击并选择「以管理员身份运行」';

  @override
  String get errorInitializationFailed => '初始化失败';

  @override
  String get errorPermissionCheckFailed => '权限检查失败';

  @override
  String get exit => '退出';

  @override
  String get simpleMode => '简单模式';

  @override
  String get advancedMode => '高级模式';

  @override
  String get connect => '连接';

  @override
  String get disconnect => '断开';

  @override
  String get connectionStatus => '连接状态';

  @override
  String get connected => '已连接';

  @override
  String get connecting => '连接中';

  @override
  String get disconnected => '未连接';

  @override
  String get disconnecting => '断开中';

  @override
  String get error => '错误';

  @override
  String get subscriptionUrl => '订阅链接';

  @override
  String get subscriptionUrlHint => '在此粘贴您的订阅链接';

  @override
  String get updateSubscription => '更新订阅';

  @override
  String get addSubscription => '添加订阅';

  @override
  String get proxyMode => '代理模式';

  @override
  String get globalMode => '全局模式';

  @override
  String get smartMode => '智能分流';

  @override
  String get directMode => '直连模式';

  @override
  String get currentNode => '当前节点';

  @override
  String get latency => '延迟';

  @override
  String get speed => '速度';

  @override
  String get uploadSpeed => '上传';

  @override
  String get downloadSpeed => '下载';

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get theme => '主题';

  @override
  String get lightTheme => '浅色';

  @override
  String get darkTheme => '深色';

  @override
  String get systemTheme => '跟随系统';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get checkUpdate => '检查更新';

  @override
  String get switchToSimpleMode => '切换到简单模式';

  @override
  String get switchToAdvancedMode => '切换到高级模式';

  @override
  String get invalidUrl => '无效的链接';

  @override
  String get pleaseEnterUrl => '请输入订阅链接';

  @override
  String get updateSuccess => '更新成功';

  @override
  String get updateFailed => '更新失败';

  @override
  String get connectSuccess => '连接成功';

  @override
  String get connectFailed => '连接失败';

  @override
  String get disconnectSuccess => '断开成功';

  @override
  String get noAvailableNode => '没有可用节点';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get ok => '确定';

  @override
  String get clear => '清空';

  @override
  String get close => '关闭';

  @override
  String get moreInfo => '更多信息';

  @override
  String get paste => '粘贴';

  @override
  String get noAdminPrivileges => '未以管理员权限运行';

  @override
  String get noAdminPrivilegesHint => '系统代理设置可能需要管理员权限。如果遇到问题，请以管理员身份重新运行应用。';

  @override
  String get adminPrivilegesRequired => '需要管理员权限';

  @override
  String get adminPrivilegesExplanation =>
      '修改系统代理设置通常需要管理员权限。如果您在启用系统代理时遇到权限错误，请按照以下说明以管理员身份运行应用。';

  @override
  String get howToRunAsAdmin => '如何以管理员身份运行';

  @override
  String get windowsAdminInstructions => '右键点击应用图标，选择「以管理员身份运行」';

  @override
  String get macosAdminInstructions => '在终端中使用 sudo 命令运行，或者在系统偏好设置中授予权限';

  @override
  String get linuxAdminInstructions => '使用 sudo 命令运行，或者将用户添加到相应的权限组';

  @override
  String get globalModeDescription => '所有流量走代理';

  @override
  String get smartModeDescription => '国外网站走代理，国内直连';

  @override
  String get directModeDescription => '所有流量直连';

  @override
  String get subscriptionConfig => '订阅配置';

  @override
  String get save => '保存';

  @override
  String get saveSuccess => '保存成功';

  @override
  String get nodeSelection => '节点选择';

  @override
  String get selectNode => '选择节点';

  @override
  String get pleaseSelectNode => '请先选择一个节点';

  @override
  String get noServersAvailable => '没有可用服务器';

  @override
  String get pleaseUpdateSubscription => '请更新订阅以获取服务器';

  @override
  String get totalServers => '服务器总数';

  @override
  String get refresh => '刷新';

  @override
  String get change => '更改';

  @override
  String get unknownError => '发生未知错误';

  @override
  String get networkError => '网络错误';

  @override
  String get networkTimeoutError => '网络请求超时，请检查您的网络连接后重试。';

  @override
  String get dnsResolutionError => '域名解析失败，请检查您的DNS设置。';

  @override
  String get connectionRefusedError => '连接被拒绝，服务器可能已关闭或无法访问。';

  @override
  String get noInternetError => '无网络连接，请检查您的网络设置。';

  @override
  String get sslCertificateError => 'SSL证书验证失败，连接可能不安全。';

  @override
  String get subscriptionError => '订阅错误';

  @override
  String get invalidSubscriptionUrl => '无效的订阅链接，请检查链接后重试。';

  @override
  String get subscriptionParseError => '订阅数据解析失败，订阅格式可能不正确。';

  @override
  String get emptySubscriptionError => '订阅中未找到服务器，请检查订阅链接。';

  @override
  String get subscriptionNotFoundError => '订阅未找到，链接可能不正确或已过期。';

  @override
  String get subscriptionUnauthorizedError => '订阅访问未授权，请检查您的凭据。';

  @override
  String get connectionError => '连接错误';

  @override
  String get connectionTimeoutError => '连接超时，请重试。';

  @override
  String get noServerSelectedError => '未选择服务器，请先选择一个服务器。';

  @override
  String get alreadyConnectedError => '已经连接，请先断开连接。';

  @override
  String get notConnectedError => '未连接，请先连接。';

  @override
  String get configError => '配置错误';

  @override
  String get invalidConfigError => '无效的配置，请检查您的设置。';

  @override
  String get missingConfigError => '缺少必需的配置，请完成您的设置。';

  @override
  String get permissionError => '权限错误';

  @override
  String get vpnPermissionError => 'VPN权限被拒绝，请在系统设置中授予VPN权限。';

  @override
  String get networkPermissionError => '网络权限被拒绝，请授予网络权限。';

  @override
  String get storagePermissionError => '存储权限被拒绝，请授予存储权限。';

  @override
  String get networkErrorSuggestion => '请检查您的网络连接后重试。';

  @override
  String get subscriptionErrorSuggestion => '请验证订阅链接并重新更新。';

  @override
  String get connectionErrorSuggestion => '请检查您的服务器设置和网络连接。';

  @override
  String get permissionErrorSuggestion => '请在系统设置中授予所需的权限。';

  @override
  String get retry => '重试';

  @override
  String get retrying => '重试中...';

  @override
  String retryIn(int seconds) {
    return '$seconds秒后重试';
  }

  @override
  String get loading => '加载中...';

  @override
  String get pleaseWait => '请稍候...';

  @override
  String get operationInProgress => '操作进行中...';

  @override
  String get systemProxy => '系统代理';

  @override
  String get proxySettings => '代理设置';

  @override
  String get systemProxyEnabled => '系统代理已启用';

  @override
  String get systemProxyDisabled => '系统代理已禁用';

  @override
  String get systemProxyEnabledSuccess => '系统代理启用成功';

  @override
  String get systemProxyDisabledSuccess => '系统代理禁用成功';

  @override
  String get systemProxyError => '系统代理设置失败';

  @override
  String get autoSetSystemProxy => '自动设置系统代理';

  @override
  String get autoSetSystemProxyDescription => '连接时自动设置系统代理';
}
