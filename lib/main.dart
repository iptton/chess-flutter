import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '国际象棋',
      theme: _buildCustomTheme(),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildCustomTheme() {
    // 基于 foreground.png 和 background.png 的精确配色方案
    // 采用分层图标设计原理：前景深色、背景浅色的专业配色
    const Color primaryColor = Color(0xFF2D3748); // 深灰蓝 - 对应前景图层的深色调
    const Color backgroundColor = Color(0xFFF7FAFC); // 极浅蓝灰 - 对应背景图层的浅色调
    const Color accentColor = Color(0xFF4299E1); // 明亮蓝 - 主要交互色
    const Color secondaryColor = Color(0xFF48BB78); // 绿色 - 成功状态色
    const Color surfaceColor = Color(0xFFFFFFFF); // 纯白 - 卡片表面
    const Color onSurfaceColor = Color(0xFF1A202C); // 深色文字

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: surfaceColor,
        background: backgroundColor,
        onPrimary: surfaceColor,
        onSecondary: surfaceColor,
        onTertiary: surfaceColor,
        onSurface: onSurfaceColor,
        onBackground: onSurfaceColor,
        outline: primaryColor.withOpacity(0.2),
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: surfaceColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: surfaceColor,
          elevation: 2,
          shadowColor: primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 3,
        shadowColor: primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
