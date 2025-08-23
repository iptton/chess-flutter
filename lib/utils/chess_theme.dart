import 'package:flutter/material.dart';

class ChessTheme {
  final Color lightSquareColor;
  final Color darkSquareColor;
  final Color selectedSquareColor;
  final Color validMoveColor;
  final Color hintColor;
  final Color checkColor;
  final Color boardBorderColor;
  final TextStyle labelTextStyle;
  final TextStyle turnIndicatorStyle;
  final TextStyle moveMessageStyle;
  final ButtonStyle controlButtonStyle;

  const ChessTheme({
    this.lightSquareColor = const Color(0xFFF7FAFC), // 匹配背景图层的浅色调
    this.darkSquareColor = const Color(0xFF2D3748), // 匹配前景图层的深色调
    this.selectedSquareColor = const Color(0x4D4299E1), // 明亮蓝色透明
    this.validMoveColor = const Color(0x4D48BB78), // 绿色透明 - 有效移动
    this.hintColor = const Color(0x4D81C784), // 深绿色透明 - 提示
    this.checkColor = const Color(0x4DE53E3E), // 红色透明 - 将军
    this.boardBorderColor = const Color(0xFF2D3748), // 主色边框
    this.labelTextStyle = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1A202C),
    ),
    this.turnIndicatorStyle = const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1A202C),
    ),
    this.moveMessageStyle = const TextStyle(
      fontSize: 16,
      color: Color(0xFF1A202C),
    ),
    this.controlButtonStyle = const ButtonStyle(),
  });

  // 预设主题 - 基于 foreground.png 和 background.png 的精确配色
  static const ChessTheme classic = ChessTheme();

  static const ChessTheme modern = ChessTheme(
    lightSquareColor: Color(0xFFEDF2F7), // 更深一点的浅色
    darkSquareColor: Color(0xFF4A5568), // 中等灰色
    selectedSquareColor: Color(0x4D4299E1),
    validMoveColor: Color(0x4D48BB78),
    hintColor: Color(0x4D68D391),
    checkColor: Color(0x4DF56565),
  );

  static const ChessTheme dark = ChessTheme(
    lightSquareColor: Color(0xFF4A5568), // 深灰色
    darkSquareColor: Color(0xFF1A202C), // 极深色
    selectedSquareColor: Color(0x4D63B3ED),
    validMoveColor: Color(0x4D68D391),
    hintColor: Color(0x4D9AE6B4),
    checkColor: Color(0x4DF687B3),
    boardBorderColor: Color(0xFFE2E8F0),
    labelTextStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Color(0xFFE2E8F0),
    ),
    turnIndicatorStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Color(0xFFE2E8F0),
    ),
    moveMessageStyle: TextStyle(
      fontSize: 16,
      color: Color(0xFFE2E8F0),
    ),
  );

  ChessTheme copyWith({
    Color? lightSquareColor,
    Color? darkSquareColor,
    Color? selectedSquareColor,
    Color? validMoveColor,
    Color? hintColor,
    Color? checkColor,
    Color? boardBorderColor,
    TextStyle? labelTextStyle,
    TextStyle? turnIndicatorStyle,
    TextStyle? moveMessageStyle,
    ButtonStyle? controlButtonStyle,
  }) {
    return ChessTheme(
      lightSquareColor: lightSquareColor ?? this.lightSquareColor,
      darkSquareColor: darkSquareColor ?? this.darkSquareColor,
      selectedSquareColor: selectedSquareColor ?? this.selectedSquareColor,
      validMoveColor: validMoveColor ?? this.validMoveColor,
      hintColor: hintColor ?? this.hintColor,
      checkColor: checkColor ?? this.checkColor,
      boardBorderColor: boardBorderColor ?? this.boardBorderColor,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      turnIndicatorStyle: turnIndicatorStyle ?? this.turnIndicatorStyle,
      moveMessageStyle: moveMessageStyle ?? this.moveMessageStyle,
      controlButtonStyle: controlButtonStyle ?? this.controlButtonStyle,
    );
  }

  // 更新了从主题色创建象棋主题的工厂方法
  factory ChessTheme.fromAppTheme({
    required Color primaryColor,
    required Color backgroundColor,
    required Color accentColor,
    required Color secondaryColor,
  }) {
    return ChessTheme(
      lightSquareColor: backgroundColor,
      darkSquareColor: primaryColor,
      selectedSquareColor: accentColor.withOpacity(0.3),
      validMoveColor: secondaryColor.withOpacity(0.3),
      hintColor: secondaryColor.withOpacity(0.4),
      checkColor: const Color(0x4DE53E3E),
      boardBorderColor: primaryColor,
      labelTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1A202C),
      ),
      turnIndicatorStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A202C),
      ),
      moveMessageStyle: TextStyle(
        fontSize: 16,
        color: const Color(0xFF1A202C),
      ),
    );
  }
}
