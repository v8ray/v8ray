/// V8Ray 语言状态管理
///
/// 管理应用的语言设置

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../utils/logger.dart';

/// 语言Provider
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

/// 语言状态管理
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  /// 从本地存储加载语言设置
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(StorageKeys.languageCode);

      if (languageCode != null) {
        state = Locale(languageCode);
        appLogger.info('Loaded locale: $languageCode');
      } else {
        // 默认使用英文
        state = const Locale('en');
        appLogger.info('Using default locale: en');
      }
    } catch (e, stackTrace) {
      appLogger.error('Failed to load locale', e, stackTrace);
      state = const Locale('en');
    }
  }

  /// 设置语言
  Future<void> setLocale(Locale locale) async {
    try {
      state = locale;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.languageCode, locale.languageCode);
      appLogger.info('Locale changed to: ${locale.languageCode}');
    } catch (e, stackTrace) {
      appLogger.error('Failed to save locale', e, stackTrace);
    }
  }

  /// 切换到英文
  Future<void> setEnglish() => setLocale(const Locale('en'));

  /// 切换到中文
  Future<void> setChinese() => setLocale(const Locale('zh'));
}

/// 支持的语言列表
final supportedLocalesProvider = Provider<List<Locale>>((ref) {
  return const [
    Locale('en'), // English
    Locale('zh'), // 简体中文
  ];
});
