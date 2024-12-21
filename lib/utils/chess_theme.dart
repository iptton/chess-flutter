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
    this.lightSquareColor = const Color(0xFFEED7BE),
    this.darkSquareColor = const Color(0xFFB58863),
    this.selectedSquareColor = const Color(0x4D3F88C5),
    this.validMoveColor = const Color(0x4DFFEB3B),
    this.hintColor = const Color(0x4D4CAF50),
    this.checkColor = const Color(0x4DFF5252),
    this.boardBorderColor = Colors.black,
    this.labelTextStyle = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ),
    this.turnIndicatorStyle = const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: Colors.black87,
    ),
    this.moveMessageStyle = const TextStyle(
      fontSize: 16,
      color: Colors.black87,
    ),
    this.controlButtonStyle = const ButtonStyle(),
  });

  // 预设主题
  static const ChessTheme classic = ChessTheme();

  static const ChessTheme modern = ChessTheme(
    lightSquareColor: Color(0xFFF0D9B5),
    darkSquareColor: Color(0xFFB58863),
    selectedSquareColor: Color(0x4D2196F3),
    validMoveColor: Color(0x4D4CAF50),
    hintColor: Color(0x4DFFEB3B),
    checkColor: Color(0x4DFF5252),
  );

  static const ChessTheme dark = ChessTheme(
    lightSquareColor: Color(0xFF4A4A4A),
    darkSquareColor: Color(0xFF262626),
    selectedSquareColor: Color(0x4D64B5F6),
    validMoveColor: Color(0x4D81C784),
    hintColor: Color(0x4DFFF176),
    checkColor: Color(0x4DE57373),
    boardBorderColor: Colors.white54,
    labelTextStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.white70,
    ),
    turnIndicatorStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: Colors.white70,
    ),
    moveMessageStyle: TextStyle(
      fontSize: 16,
      color: Colors.white70,
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
} 