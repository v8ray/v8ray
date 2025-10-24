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
  String get testLatency => '测试延迟';

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
  String get currentVersion => '当前版本';

  @override
  String get latestVersion => '最新版本';

  @override
  String get checkingUpdate => '正在检查更新...';

  @override
  String get updateAvailable => '发现新版本';

  @override
  String get noUpdateAvailable => '已是最新版本';

  @override
  String get downloadUpdate => '下载更新';

  @override
  String get downloading => '下载中...';

  @override
  String get downloadProgress => '下载进度';

  @override
  String get updateDownloaded => '更新已下载';

  @override
  String get installUpdate => '安装更新';

  @override
  String get restartToUpdate => '重启以更新';

  @override
  String get updateInstalled => '更新已安装';

  @override
  String get restartToApplyUpdate => '更新已成功安装，请重启应用以应用更新。';

  @override
  String get restartNow => '立即重启';

  @override
  String get updateInstallFailed => '安装更新失败';

  @override
  String get unknownError => '发生未知错误';

  @override
  String get close => '关闭';

  @override
  String get updateCheckFailed => '检查更新失败';

  @override
  String get updateDownloadFailed => '下载更新失败';

  @override
  String newVersionAvailable(String version) {
    return '发现新版本 $version';
  }

  @override
  String get updateNow => '立即更新';

  @override
  String get later => '稍后';

  @override
  String get releaseNotes => '更新说明';

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

  @override
  String get disconnectToChangeProxyMode => '请先断开连接才能修改代理模式';

  @override
  String get xrayCoreVersion => 'Xray Core 版本';

  @override
  String get xrayCoreCurrentVersion => '当前 Xray Core';

  @override
  String get xrayCoreLatestVersion => '最新 Xray Core';

  @override
  String get checkingXrayCoreUpdate => '正在检查 Xray Core 更新...';

  @override
  String get xrayCoreUpdateAvailable => 'Xray Core 有新版本';

  @override
  String get noXrayCoreUpdateAvailable => 'Xray Core 已是最新版本';

  @override
  String get downloadXrayCoreUpdate => '下载 Xray Core 更新';

  @override
  String get downloadingXrayCore => '正在下载 Xray Core...';

  @override
  String get xrayCoreUpdateDownloaded => 'Xray Core 更新已下载';

  @override
  String get installXrayCoreUpdate => '安装 Xray Core 更新';

  @override
  String get xrayCoreUpdateCheckFailed => '检查 Xray Core 更新失败';

  @override
  String get xrayCoreUpdateDownloadFailed => '下载 Xray Core 更新失败';

  @override
  String newXrayCoreVersionAvailable(String version) {
    return '发现新的 Xray Core 版本 $version';
  }

  @override
  String get xrayCoreNotInstalled => 'Xray Core 未安装';

  @override
  String get checkXrayCoreUpdate => '检查 Xray Core 更新';

  @override
  String get xrayCoreUpdateInstalled => 'Xray Core 更新成功';

  @override
  String get xrayCoreUpdateInstallFailed => '安装 Xray Core 更新失败';

  @override
  String get dashboard => '仪表板';

  @override
  String get nodes => '节点';

  @override
  String get subscriptions => '订阅';

  @override
  String get logs => '日志';

  @override
  String get connectionInfo => '连接信息';

  @override
  String get currentNodeInfo => '当前节点';

  @override
  String get proxyModeInfo => '代理模式';

  @override
  String get systemStatus => '系统状态';

  @override
  String get trafficStatistics => '流量统计';

  @override
  String get quickActions => '快速操作';

  @override
  String get switchNode => '切换节点';

  @override
  String get nodeManagement => '节点管理';

  @override
  String get subscriptionManagement => '订阅管理';

  @override
  String get search => '搜索';

  @override
  String get addNode => '添加节点';

  @override
  String get sortBy => '排序方式';

  @override
  String get filterBy => '筛选条件';

  @override
  String get groupBy => '分组方式';

  @override
  String get all => '全部';

  @override
  String get available => '可用';

  @override
  String get unavailable => '不可用';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get test => '测试';

  @override
  String get subscriptionList => '订阅列表';

  @override
  String get subscriptionSettings => '订阅设置';

  @override
  String get autoUpdateInterval => '自动更新间隔';

  @override
  String get retryOnFailure => '失败重试';

  @override
  String get nodeFilterRules => '节点过滤规则';

  @override
  String get lastUpdate => '最后更新';

  @override
  String get nodeCount => '节点数量';

  @override
  String get autoUpdate => '自动更新';

  @override
  String get enabled => '已启用';

  @override
  String get disabled => '已禁用';

  @override
  String get logLevel => '日志级别';

  @override
  String get clearLogs => '清空日志';

  @override
  String get exportLogs => '导出日志';

  @override
  String get basicSettings => '基础设置';

  @override
  String get routingRules => '路由规则';

  @override
  String get dnsSettings => 'DNS设置';

  @override
  String get advancedSettings => '高级设置';

  @override
  String get startOnBoot => '开机启动';

  @override
  String get minimizeToTray => '最小化到托盘';

  @override
  String get autoConnect => '自动连接';

  @override
  String get checkForUpdates => '检查更新';

  @override
  String get notificationSettings => '通知设置';

  @override
  String get connectionStatusChange => '连接状态变化';

  @override
  String get subscriptionUpdate => '订阅更新';

  @override
  String get errorNotification => '错误通知';

  @override
  String get localPort => '本地端口';

  @override
  String get allowLan => '允许局域网';

  @override
  String get httpProxy => 'HTTP代理';

  @override
  String get httpsProxy => 'HTTPS代理';

  @override
  String get pacMode => 'PAC模式';

  @override
  String get tunMode => 'TUN模式';

  @override
  String get tunDevice => 'TUN设备';

  @override
  String get tunNetwork => 'TUN网段';

  @override
  String get running => '运行中';

  @override
  String get stopped => '已停止';

  @override
  String get normal => '正常';

  @override
  String get totalUpload => '总上传';

  @override
  String get totalDownload => '总下载';

  @override
  String get connectionDuration => '连接时长';

  @override
  String get hours => '小时';

  @override
  String get minutes => '分钟';

  @override
  String get seconds => '秒';

  @override
  String get never => '从未';

  @override
  String get pleaseAddSubscription => '请先添加订阅';

  @override
  String get noSubscriptions => '暂无订阅';
}
