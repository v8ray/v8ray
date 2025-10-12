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
  String get paste => '粘贴';

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
}
