/// V8Ray 高级模式页面
///
/// 高级模式的主界面，包含仪表板、节点管理、订阅管理和日志查看

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../widgets/app_update_checker.dart';
import '../widgets/language_selector.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/logs_tab.dart';
import 'tabs/nodes_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/subscriptions_tab.dart';

/// 高级模式页面
class AdvancedModePage extends ConsumerStatefulWidget {
  const AdvancedModePage({super.key});

  @override
  ConsumerState<AdvancedModePage> createState() => _AdvancedModePageState();
}

class _AdvancedModePageState extends ConsumerState<AdvancedModePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.advancedMode),
        actions: [
          // 应用更新检查
          const AppUpdateChecker(),

          // 语言选择器
          const LanguageSelector(),

          // 切换回简单模式
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            tooltip: l10n.switchToSimpleMode,
            onPressed: () => context.goToSimpleMode(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(icon: const Icon(Icons.dashboard), text: l10n.dashboard),
            Tab(icon: const Icon(Icons.dns), text: l10n.nodes),
            Tab(
              icon: const Icon(Icons.subscriptions),
              text: l10n.subscriptions,
            ),
            Tab(icon: const Icon(Icons.article), text: l10n.logs),
            Tab(icon: const Icon(Icons.settings), text: l10n.settings),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DashboardTab(),
          NodesTab(),
          SubscriptionsTab(),
          LogsTab(),
          SettingsTab(),
        ],
      ),
    );
  }
}
