/// V8Ray 路由配置
///
/// 使用go_router管理应用路由

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/pages/simple_mode_page.dart';
import '../../presentation/pages/advanced_mode_page.dart';
import '../../presentation/pages/settings_page.dart';
import '../../presentation/pages/about_page.dart';
import '../constants/app_constants.dart';

/// 应用路由配置
class AppRouter {
  AppRouter._();

  /// 路由配置
  static final GoRouter router = GoRouter(
    initialLocation: RoutePaths.simpleHome,
    debugLogDiagnostics: true,
    routes: [
      // 简单模式主页
      GoRoute(
        path: RoutePaths.simpleHome,
        name: 'simple',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SimpleModePage(),
        ),
      ),

      // 高级模式主页
      GoRoute(
        path: RoutePaths.advancedHome,
        name: 'advanced',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AdvancedModePage(),
        ),
      ),

      // 设置页面
      GoRoute(
        path: RoutePaths.settings,
        name: 'settings',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SettingsPage(),
        ),
      ),

      // 关于页面
      GoRoute(
        path: RoutePaths.about,
        name: 'about',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AboutPage(),
        ),
      ),
    ],

    // 错误页面
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RoutePaths.simpleHome),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 路由扩展方法
extension AppRouterExtension on BuildContext {
  /// 导航到简单模式
  void goToSimpleMode() => go(RoutePaths.simpleHome);

  /// 导航到高级模式
  void goToAdvancedMode() => go(RoutePaths.advancedHome);

  /// 导航到设置页面
  void goToSettings() => go(RoutePaths.settings);

  /// 导航到关于页面
  void goToAbout() => go(RoutePaths.about);
}

