/// V8Ray 语言选择器组件
///
/// 提供语言切换功能的下拉菜单

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/locale_provider.dart';

/// 语言选择器组件
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.translate),
      tooltip: 'Language / 语言',
      onSelected: (locale) {
        ref.read(localeProvider.notifier).setLocale(locale);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: const Locale('en'),
          child: Row(
            children: [
              if (currentLocale.languageCode == 'en')
                const Icon(Icons.check, size: 20)
              else
                const SizedBox(width: 20),
              const SizedBox(width: 12),
              const Text('English'),
            ],
          ),
        ),
        PopupMenuItem(
          value: const Locale('zh'),
          child: Row(
            children: [
              if (currentLocale.languageCode == 'zh')
                const Icon(Icons.check, size: 20)
              else
                const SizedBox(width: 20),
              const SizedBox(width: 12),
              const Text('简体中文'),
            ],
          ),
        ),
      ],
    );
  }
}
