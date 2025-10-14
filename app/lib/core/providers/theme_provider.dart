/// V8Ray 主题状态管理
///
/// 管理应用的主题模式（浅色/深色/跟随系统）

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../utils/logger.dart';

/// 主题模式Provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier();
});

/// 主题模式状态管理
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  /// 从本地存储加载主题模式
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(StorageKeys.themeMode);

      if (themeModeString != null) {
        state = _parseThemeMode(themeModeString);
        appLogger.info('Loaded theme mode: $state');
      } else {
        // 默认跟随系统
        state = ThemeMode.system;
        appLogger.info('Using default theme mode: system');
      }
    } catch (e, stackTrace) {
      appLogger.error('Failed to load theme mode', e, stackTrace);
      state = ThemeMode.system;
    }
  }

  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      state = mode;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.themeMode, _themeModeToString(mode));

      appLogger.info('Theme mode changed to: $mode');
    } catch (e, stackTrace) {
      appLogger.error('Failed to save theme mode', e, stackTrace);
    }
  }

  /// 切换到浅色主题
  Future<void> setLightMode() => setThemeMode(ThemeMode.light);

  /// 切换到深色主题
  Future<void> setDarkMode() => setThemeMode(ThemeMode.dark);

  /// 切换到跟随系统
  Future<void> setSystemMode() => setThemeMode(ThemeMode.system);

  /// 解析主题模式字符串
  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// 将主题模式转换为字符串
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

/// 当前是否为深色模式Provider
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  // 注意：这里简化处理，实际应该根据系统主题判断
  // 在实际使用时，需要通过BuildContext获取系统主题
  return themeMode == ThemeMode.dark;
});
