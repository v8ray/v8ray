import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/error/index.dart';
import 'core/l10n/app_localizations.dart';
import 'core/providers/index.dart';
import 'core/router/index.dart';
import 'core/theme/index.dart';
import 'core/utils/index.dart';

/// V8Ray 应用入口
void main() {
  // 初始化错误处理器
  ErrorHandler.initialize();

  // 初始化日志
  appLogger.info('V8Ray application starting...');

  runApp(
    const ProviderScope(
      child: V8RayApp(),
    ),
  );
}

/// V8Ray 应用主类
class V8RayApp extends ConsumerWidget {
  const V8RayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听主题模式
    final themeMode = ref.watch(themeModeProvider);
    // 监听语言设置
    final locale = ref.watch(localeProvider);

    appLogger.info('Building app with theme: $themeMode, locale: $locale');

    return MaterialApp.router(
      // 应用标题
      title: 'V8Ray',
      debugShowCheckedModeBanner: false,

      // 路由配置
      routerConfig: AppRouter.router,

      // 主题配置
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // 国际化配置
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('zh'), // 简体中文
      ],
      locale: locale,
    );
  }
}
