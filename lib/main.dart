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
      debugShowCheckedModeBanner: false,
      title: '一起下棋',
      theme: _buildCustomTheme(),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildCustomTheme() {
    // 基于新设计的配色方案
    const Color primaryColor = Color(0xFF1F2937); // 深灰 - 主要按钮色
    const Color backgroundColor = Color(0xFFF1F5F9); // 浅灰蓝 - 背景色
    const Color accentColor = Color(0xFF8B5CF6); // 紫色 - 悬停和强调色
    const Color secondaryColor = Color(0xFF6B7280); // 中灰 - 次要文字色
    const Color surfaceColor = Color(0xFFFFFFFF); // 纯白 - 卡片表面
    const Color onSurfaceColor = Color(0xFF1F2937); // 深色文字
    const Color borderColor = Color(0xFFD1D5DB); // 边框色

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
        outline: borderColor,
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
          elevation: 0,
          shadowColor: accentColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
