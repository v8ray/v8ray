/// V8Ray 设置标签页
///
/// 应用设置页面，包括基础设置、代理设置、路由规则等

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/utils/responsive.dart';

/// 设置标签页
class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: EdgeInsets.all(
        Responsive(context).valueWhen(
          mobile: UIConstants.defaultPadding,
          tablet: UIConstants.largePadding,
          desktop: UIConstants.largePadding * 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 基础设置
          _buildBasicSettings(context, ref, l10n),
          const SizedBox(height: UIConstants.defaultPadding),

          // 代理设置
          _buildProxySettings(context, l10n),
          const SizedBox(height: UIConstants.defaultPadding),

          // 通知设置
          _buildNotificationSettings(context, l10n),
          const SizedBox(height: UIConstants.defaultPadding),

          // 高级设置
          _buildAdvancedSettings(context, l10n),
        ],
      ),
    );
  }

  /// 构建基础设置卡片
  Widget _buildBasicSettings(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.basicSettings,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 界面语言
            _buildSettingItem(
              context,
              l10n,
              l10n.language,
              DropdownButton<Locale?>(
                value: locale,
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text('${l10n.systemTheme} / System'),
                  ),
                  const DropdownMenuItem(
                    value: Locale('en'),
                    child: Text('English'),
                  ),
                  const DropdownMenuItem(
                    value: Locale('zh'),
                    child: Text('简体中文'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref.read(localeProvider.notifier).setLocale(value);
                  }
                },
              ),
            ),
            const Divider(),

            // 主题模式
            _buildSettingItem(
              context,
              l10n,
              l10n.theme,
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l10n.lightTheme),
                    icon: const Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l10n.darkTheme),
                    icon: const Icon(Icons.dark_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l10n.systemTheme),
                    icon: const Icon(Icons.brightness_auto),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (Set<ThemeMode> newSelection) {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(newSelection.first);
                },
              ),
            ),
            const Divider(),

            // 开机启动
            _buildSwitchItem(context, l10n, l10n.startOnBoot, false, (value) {
              // TODO: 实现开机启动设置
            }),
            const Divider(),

            // 最小化到托盘
            _buildSwitchItem(context, l10n, l10n.minimizeToTray, true, (value) {
              // TODO: 实现最小化到托盘设置
            }),
            const Divider(),

            // 自动连接
            _buildSwitchItem(context, l10n, l10n.autoConnect, false, (value) {
              // TODO: 实现自动连接设置
            }),
            const Divider(),

            // 检查更新
            _buildSwitchItem(context, l10n, l10n.checkForUpdates, true, (
              value,
            ) {
              // TODO: 实现检查更新设置
            }),
          ],
        ),
      ),
    );
  }

  /// 构建代理设置卡片
  Widget _buildProxySettings(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.router,
                  size: 24,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.proxySettings,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 本地端口
            _buildTextFieldItem(
              context,
              l10n,
              '${l10n.localPort} (HTTP)',
              '7890',
              (value) {
                // TODO: 实现本地端口设置
              },
            ),
            const Divider(),

            _buildTextFieldItem(
              context,
              l10n,
              '${l10n.localPort} (SOCKS)',
              '7891',
              (value) {
                // TODO: 实现本地端口设置
              },
            ),
            const Divider(),

            // 允许局域网
            _buildSwitchItem(context, l10n, l10n.allowLan, false, (value) {
              // TODO: 实现允许局域网设置
            }),
            const Divider(),

            // HTTP代理
            _buildSwitchItem(context, l10n, l10n.httpProxy, true, (value) {
              // TODO: 实现HTTP代理设置
            }),
            const Divider(),

            // HTTPS代理
            _buildSwitchItem(context, l10n, l10n.httpsProxy, true, (value) {
              // TODO: 实现HTTPS代理设置
            }),
            const Divider(),

            // PAC模式
            _buildSwitchItem(context, l10n, l10n.pacMode, false, (value) {
              // TODO: 实现PAC模式设置
            }),
          ],
        ),
      ),
    );
  }

  /// 构建通知设置卡片
  Widget _buildNotificationSettings(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications,
                  size: 24,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.notificationSettings,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 连接状态变化
            _buildSwitchItem(context, l10n, l10n.connectionStatusChange, true, (
              value,
            ) {
              // TODO: 实现通知设置
            }),
            const Divider(),

            // 订阅更新
            _buildSwitchItem(context, l10n, l10n.subscriptionUpdate, true, (
              value,
            ) {
              // TODO: 实现通知设置
            }),
            const Divider(),

            // 错误提醒
            _buildSwitchItem(context, l10n, l10n.errorNotification, true, (
              value,
            ) {
              // TODO: 实现通知设置
            }),
          ],
        ),
      ),
    );
  }

  /// 构建高级设置卡片
  Widget _buildAdvancedSettings(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  size: 24,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.advancedSettings,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 路由规则
            _buildSettingItem(
              context,
              l10n,
              l10n.routingRules,
              OutlinedButton(
                onPressed: () {
                  // TODO: 实现路由规则设置
                },
                child: Text(l10n.settings),
              ),
            ),
            const Divider(),

            // DNS设置
            _buildSettingItem(
              context,
              l10n,
              l10n.dnsSettings,
              OutlinedButton(
                onPressed: () {
                  // TODO: 实现DNS设置
                },
                child: Text(l10n.settings),
              ),
            ),
            const Divider(),

            // 日志级别
            _buildSettingItem(
              context,
              l10n,
              l10n.logLevel,
              DropdownButton<String>(
                value: 'info',
                items: const [
                  DropdownMenuItem(value: 'debug', child: Text('DEBUG')),
                  DropdownMenuItem(value: 'info', child: Text('INFO')),
                  DropdownMenuItem(value: 'warning', child: Text('WARNING')),
                  DropdownMenuItem(value: 'error', child: Text('ERROR')),
                ],
                onChanged: (value) {
                  // TODO: 实现日志级别设置
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建设置项
  Widget _buildSettingItem(
    BuildContext context,
    AppLocalizations l10n,
    String label,
    Widget control,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          control,
        ],
      ),
    );
  }

  /// 构建开关项
  Widget _buildSwitchItem(
    BuildContext context,
    AppLocalizations l10n,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  /// 构建文本输入项
  Widget _buildTextFieldItem(
    BuildContext context,
    AppLocalizations l10n,
    String label,
    String initialValue,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          SizedBox(
            width: 120,
            child: TextField(
              controller: TextEditingController(text: initialValue),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
