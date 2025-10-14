/// V8Ray 高级模式页面
///
/// 高级模式的主界面（占位，稍后实现）

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../widgets/language_selector.dart';

class AdvancedModePage extends ConsumerWidget {
  const AdvancedModePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.advancedMode),
        actions: [
          // 语言选择器
          const LanguageSelector(),

          // 切换回简单模式
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            tooltip: l10n.switchToSimpleMode,
            onPressed: () => context.goToSimpleMode(),
          ),
        ],
      ),
      body: const Center(child: Text('Advanced Mode Page - To be implemented')),
    );
  }
}
