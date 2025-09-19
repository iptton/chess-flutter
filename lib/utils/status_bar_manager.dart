import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 状态栏管理工具类
/// 统一管理应用中的状态栏颜色设置
class StatusBarManager {
  /// 设置主屏幕状态栏（统一深色背景样式）
  static void setHomeScreenStatusBar(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF667EEA),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  /// 设置游戏屏幕状态栏（深色背景，浅色图标）
  static void setGameScreenStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF667EEA),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  /// 设置学习屏幕状态栏（深色背景，浅色图标）
  static void setLearningScreenStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF667EEA),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  /// 设置设置屏幕状态栏（深色背景，浅色图标）
  static void setSettingsScreenStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF667EEA),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  /// 设置默认状态栏（浅色背景，深色图标）
  static void setDefaultStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// 延迟设置状态栏（确保在布局完成后执行）
  static void setStatusBarDelayed(VoidCallback statusBarSetter) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      statusBarSetter();
    });
  }
}
