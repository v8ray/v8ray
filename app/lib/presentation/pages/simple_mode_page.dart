/// V8Ray 简单模式页面
///
/// 简单模式的主界面

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../widgets/connection_status_card.dart';
import '../widgets/language_selector.dart';
import '../widgets/proxy_mode_selector.dart';
import '../widgets/subscription_input.dart';

/// 简单模式页面
class SimpleModePage extends ConsumerWidget {
  const SimpleModePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          // 语言选择器
          const LanguageSelector(),

          // 切换到高级模式
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: l10n.switchToAdvancedMode,
            onPressed: () => context.goToAdvancedMode(),
          ),

          // 设置
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settings,
            onPressed: () => context.goToSettings(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(UIConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 连接状态卡片
              const ConnectionStatusCard(),
              const SizedBox(height: UIConstants.largePadding),

              // 订阅链接输入
              const SubscriptionInput(),
              const SizedBox(height: UIConstants.defaultPadding),

              // 代理模式选择
              const ProxyModeSelector(),
            ],
          ),
        ),
      ),
    );
  }
}
