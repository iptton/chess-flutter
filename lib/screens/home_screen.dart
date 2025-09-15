import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'game_screen.dart';
import 'replay_screen.dart';
import 'settings_screen.dart';
import 'learning_screen.dart';
import 'package:testflutter/widgets/privacy_dialog.dart' as privacy;
import '../services/privacy_service.dart';
import '../widgets/chess_board.dart';
import '../widgets/ai_difficulty_selector.dart';
import '../services/chess_ai.dart';
import '../models/chess_models.dart';

import '../utils/ai_difficulty_strategy.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // 背景渐变动画控制器 - 使用更平滑的循环
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // 页面滑入动画控制器
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    // 启动入场动画
    _slideController.forward();

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _ensurePrivacyAccepted());
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _ensurePrivacyAccepted() async {
    final accepted = await PrivacyService.isAccepted();
    if (!accepted && mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return privacy.PrivacyDialog(
            onAccept: () async {
              await PrivacyService.setAccepted(true);
              if (mounted) Navigator.of(context).pop();
            },
            onReject: () async {
              await PrivacyService.setAccepted(false);
              // 先尝试正常关闭（Android/部分平台）
              SystemNavigator.pop();
              // 再做兜底退出（桌面等平台）
              await Future.delayed(const Duration(milliseconds: 200));
              exit(0);
            },
          );
        },
      );
    }
  }

  void _startGame(String mode) {
    switch (mode) {
      case 'pvp':
        // 直接跳转到面对面对战游戏
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ChessBoard(
              gameMode: GameMode.faceToFace,
            ),
          ),
        );
        break;
      case 'ai':
        // 显示AI难度选择对话框
        _showAISettingsDialog();
        break;
      case 'review':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReplayScreen()),
        );
        break;
      case 'learn':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LearningScreen()),
        );
        break;
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
    }
  }

  void _showAISettingsDialog() {
    AIDifficultyLevel selectedDifficulty = AIDifficultyLevel.intermediate;
    PieceColor playerColor = PieceColor.white;

    showDialog(
      context: context,
      builder: (context) => AIDifficultySelector(
        currentDifficulty: selectedDifficulty,
        showAdvancedOptions: true,
        showColorSelection: true,
        initialPlayerColor: playerColor,
        onGameStart: (difficulty, color) {
          Navigator.of(context).pop(true);
          _startAdvancedAIGame(difficulty, color);
        },
      ),
    );
  }

  void _startAdvancedAIGame(
      AIDifficultyLevel difficulty, PieceColor playerColor) async {
    try {
      print('HomeScreen: === 开始执行 _startAdvancedAIGame ===');

      final aiColor =
          playerColor == PieceColor.white ? PieceColor.black : PieceColor.white;

      print('HomeScreen: 创建高级AI实例...');
      final ai = ChessAI.advanced(advancedDifficulty: difficulty);
      print('HomeScreen: AI实例创建成功: ${ai.advancedDifficulty.displayName}');

      print('HomeScreen: 检查context是否有效...');
      if (!context.mounted) {
        print('HomeScreen: 错误 - context不可用');
        return;
      }
      print('HomeScreen: context有效');

      print('HomeScreen: 尝试导航到AI对战...');

      // 直接跳转到AI对战游戏
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            print('HomeScreen: 正在构建ChessBoard...');
            return ChessBoard(
              gameMode: GameMode.offline,
              aiColor: aiColor,
              allowedPlayer: playerColor,
              advancedAI: ai,
            );
          },
        ),
      );

      print('HomeScreen: 导航完成，结果: $result');
    } catch (e, stackTrace) {
      print('HomeScreen: _startAdvancedAIGame发生异常: $e');
      print('HomeScreen: 堆栈跟踪: $stackTrace');

      // 如果高级AI失败，回退到传统AI
      print('HomeScreen: 尝试回退到传统方式...');
      _startAIGame(difficulty._toOldDifficulty(), playerColor);
    }
  }

  void _startAIGame(AIDifficulty difficulty, PieceColor playerColor) {
    final aiColor =
        playerColor == PieceColor.white ? PieceColor.black : PieceColor.white;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChessBoard(
          gameMode: GameMode.offline,
          aiDifficulty: difficulty,
          aiColor: aiColor,
          allowedPlayer: playerColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFF667EEA),
                    const Color(0xFF764BA2),
                    (math.sin(_backgroundController.value * 2 * math.pi) + 1) /
                        2,
                  )!,
                  Color.lerp(
                    const Color(0xFF764BA2),
                    const Color(0xFF667EEA),
                    (math.sin(_backgroundController.value * 2 * math.pi) + 1) /
                        2,
                  )!,
                ],
                stops: [
                  0.3 +
                      (math.sin(_backgroundController.value * 2 * math.pi) *
                          0.2),
                  0.7 -
                      (math.sin(_backgroundController.value * 2 * math.pi) *
                          0.2),
                ],
              ),
            ),
            child: Stack(
              children: [
                // 浮动棋子背景
                const FloatingPieces(),
                // 主要内容
                Center(
                  child: AnimatedBuilder(
                    animation: _slideAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Opacity(
                          opacity: 1.0 - (_slideAnimation.value / 30.0),
                          child: ChessMenuCard(
                            onStartGame: _startGame,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FloatingPieces extends StatefulWidget {
  const FloatingPieces({Key? key}) : super(key: key);

  @override
  State<FloatingPieces> createState() => _FloatingPiecesState();
}

class _FloatingPiecesState extends State<FloatingPieces>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  final List<String> pieces = ['♔', '♛', '♜', '♝', '♞', '♟'];
  final List<Alignment> positions = [
    const Alignment(-0.8, -0.6),
    const Alignment(0.7, -0.4),
    const Alignment(-0.6, 0.2),
    const Alignment(0.5, 0.6),
    const Alignment(-0.9, 0.0),
    const Alignment(0.8, -0.1),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      pieces.length,
      (index) => AnimationController(
        duration: Duration(seconds: 8 + index * 2),
        vsync: this,
      )..repeat(),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.linear),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width > 1024;

    return Stack(
      children: List.generate(pieces.length, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            final animValue = _animations[index].value;
            final floatOffset = math.sin(animValue * 2 * math.pi) * 15;
            final rotateAngle = math.sin(animValue * 2 * math.pi + index) * 0.1;

            return Positioned(
              left: (screenSize.width * 0.5) +
                  (positions[index].x * screenSize.width * 0.4),
              top: (screenSize.height * 0.5) +
                  (positions[index].y * screenSize.height * 0.4) +
                  floatOffset,
              child: Transform.rotate(
                angle: rotateAngle,
                child: Text(
                  pieces[index],
                  style: TextStyle(
                    fontSize: isLargeScreen ? 48 : 32,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class ChessBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1F2937).withOpacity(0.1);

    const squareSize = 10.0;
    for (int i = 0; i < 10; i++) {
      for (int j = 0; j < 10; j++) {
        if ((i + j) % 2 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(
              i * squareSize,
              j * squareSize,
              squareSize,
              squareSize,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ChessMenuCard extends StatefulWidget {
  final Function(String) onStartGame;

  const ChessMenuCard({
    Key? key,
    required this.onStartGame,
  }) : super(key: key);

  @override
  State<ChessMenuCard> createState() => _ChessMenuCardState();
}

class _ChessMenuCardState extends State<ChessMenuCard>
    with TickerProviderStateMixin {
  late AnimationController _titleController;
  late AnimationController _subtitleController;
  late AnimationController _crownController;
  late AnimationController _pulseController;

  late Animation<double> _titleGradientAnimation;
  late Animation<double> _subtitleFadeAnimation;
  late Animation<double> _crownBounceAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _titleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _subtitleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _crownController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _titleGradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_titleController);

    _subtitleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _subtitleController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _crownBounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: -5.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 0.0), weight: 40),
    ]).animate(_crownController);

    _pulseAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // 启动动画
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _subtitleController.forward();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _crownController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 768 && screenSize.width < 1024;
    final isDesktop = screenSize.width >= 1024;
    final isLargeDesktop = screenSize.width >= 1440;

    // 响应式尺寸计算
    double cardMaxWidth = 420;
    double cardPadding = 40;
    double titleSize = 48;
    double subtitleSize = 18;
    double buttonPadding = 19;
    double iconSize = 22;

    if (isTablet) {
      cardMaxWidth = 500;
      cardPadding = 48;
      titleSize = 56;
      subtitleSize = 20;
      buttonPadding = 24;
      iconSize = 26;
    } else if (isDesktop) {
      cardMaxWidth = 600;
      cardPadding = 64;
      titleSize = 64;
      subtitleSize = 22;
      buttonPadding = 28;
      iconSize = 29;
    } else if (isLargeDesktop) {
      cardMaxWidth = 700;
      cardPadding = 80;
      titleSize = 72;
      subtitleSize = 24;
      buttonPadding = 32;
      iconSize = 32;
    }

    return Container(
      constraints: BoxConstraints(maxWidth: cardMaxWidth),
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 25,
        shadowColor: Colors.black.withOpacity(0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        color: Colors.white.withOpacity(0.95),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Stack(
              children: [
                // 皇冠装饰
                Positioned(
                  top: -15,
                  right: -15,
                  child: AnimatedBuilder(
                    animation: _crownBounceAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _crownBounceAnimation.value),
                        child: Text(
                          '👑',
                          style: TextStyle(
                            fontSize: isDesktop ? 40 : 32,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 标题
                        AnimatedBuilder(
                          animation: _titleGradientAnimation,
                          builder: (context, child) {
                            return ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: const [
                                    Color(0xFFFF6B6B),
                                    Color(0xFF4ECDC4),
                                    Color(0xFF45B7D1),
                                  ],
                                  stops: [
                                    _titleGradientAnimation.value * 0.5,
                                    0.5 + _titleGradientAnimation.value * 0.25,
                                    1.0,
                                  ],
                                ).createShader(bounds);
                              },
                              child: Text(
                                '♔ 国际象棋 ♛',
                                style: TextStyle(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.025,
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: titleSize * 0.2),
                        // 副标题
                        AnimatedBuilder(
                          animation: _subtitleFadeAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _subtitleFadeAnimation.value,
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  10 * (1 - _subtitleFadeAnimation.value),
                                ),
                                child: Text(
                                  '选择游戏模式开始对弈',
                                  style: TextStyle(
                                    fontSize: subtitleSize,
                                    color: const Color(0xFF4A5568),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: cardPadding * 0.8),
                        // 菜单按钮
                        Column(
                          children: [
                            MenuButton(
                              icon: '👥',
                              text: '面对面对战',
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                              ),
                              onPressed: () => widget.onStartGame('pvp'),
                              delay: const Duration(milliseconds: 400),
                              buttonPadding: buttonPadding,
                              iconSize: iconSize,
                            ),
                            SizedBox(height: cardPadding * 0.3),
                            MenuButton(
                              icon: '🤖',
                              text: 'AI 对战',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                              ),
                              onPressed: () => widget.onStartGame('ai'),
                              delay: const Duration(milliseconds: 500),
                              buttonPadding: buttonPadding,
                              iconSize: iconSize,
                            ),
                            SizedBox(height: cardPadding * 0.3),
                            MenuButton(
                              icon: '📋',
                              text: '复盘',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF45B7D1), Color(0xFF96C93D)],
                              ),
                              onPressed: () => widget.onStartGame('review'),
                              delay: const Duration(milliseconds: 600),
                              buttonPadding: buttonPadding,
                              iconSize: iconSize,
                            ),
                            SizedBox(height: cardPadding * 0.3),
                            MenuButton(
                              icon: '📚',
                              text: '学习模式',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF96CEB4), Color(0xFFFECA57)],
                              ),
                              onPressed: () => widget.onStartGame('learn'),
                              delay: const Duration(milliseconds: 700),
                              buttonPadding: buttonPadding,
                              iconSize: iconSize,
                            ),
                            SizedBox(height: cardPadding * 0.3),
                            MenuButton(
                              icon: '⚙️',
                              text: '设置',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                              onPressed: () => widget.onStartGame('settings'),
                              delay: const Duration(milliseconds: 800),
                              buttonPadding: buttonPadding,
                              iconSize: iconSize,
                            ),
                          ],
                        ),
                        SizedBox(height: cardPadding * 0.8),
                        // 底部文字
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _pulseAnimation.value,
                              child: Text(
                                '🎮 享受策略与智慧的较量 🎮',
                                style: TextStyle(
                                  fontSize: subtitleSize * 0.8,
                                  color: const Color(0xFF4A5568),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MenuButton extends StatefulWidget {
  final String icon;
  final String text;
  final Gradient gradient;
  final VoidCallback onPressed;
  final Duration delay;
  final double buttonPadding;
  final double iconSize;

  const MenuButton({
    Key? key,
    required this.icon,
    required this.text,
    required this.gradient,
    required this.onPressed,
    required this.delay,
    required this.buttonPadding,
    required this.iconSize,
  }) : super(key: key);

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton> with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _pressController;
  late AnimationController _appearController;
  late AnimationController _shimmerController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _appearAnimation;
  late Animation<double> _shimmerAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _appearController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 4.0,
      end: 15.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));

    _iconScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));

    _appearAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _appearController,
      curve: Curves.easeOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    ));

    // 延迟出现动画
    Future.delayed(widget.delay, () {
      if (mounted) {
        _appearController.forward();
      }
    });
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pressController.dispose();
    _appearController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onHoverStart() {
    setState(() => _isHovered = true);
    _hoverController.forward();
    _shimmerController.repeat();
  }

  void _onHoverEnd() {
    setState(() => _isHovered = false);
    _hoverController.reverse();
    _shimmerController.stop();
    _shimmerController.reset();
  }

  void _onTapDown() {
    _pressController.forward();
  }

  void _onTapUp() {
    _pressController.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _appearAnimation,
        _scaleAnimation,
        _elevationAnimation,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _appearAnimation.value)),
          child: Opacity(
            opacity: _appearAnimation.value,
            child: Transform.scale(
              scale:
                  _scaleAnimation.value * (1.0 - _pressController.value * 0.02),
              child: Container(
                width: double.infinity,
                height: 56 + widget.buttonPadding * 0.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.1 + _elevationAnimation.value * 0.01),
                      blurRadius: 4 + _elevationAnimation.value,
                      offset: Offset(0, 4 + _elevationAnimation.value * 0.5),
                    ),
                  ],
                ),
                child: Material(
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _onTapUp,
                    onTapDown: (_) => _onTapDown(),
                    onTapCancel: _onTapCancel,
                    onHover: (hovering) {
                      if (hovering) {
                        _onHoverStart();
                      } else {
                        _onHoverEnd();
                      }
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: widget.gradient,
                      ),
                      child: Stack(
                        children: [
                          // Shimmer effect
                          if (_isHovered)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedBuilder(
                                  animation: _shimmerAnimation,
                                  builder: (context, child) {
                                    final shimmerOffset = (math.sin(
                                                    _shimmerAnimation.value *
                                                        2 *
                                                        math.pi) +
                                                1) /
                                            2 *
                                            200 -
                                        100;
                                    return Transform.translate(
                                      offset: Offset(
                                        shimmerOffset,
                                        0,
                                      ),
                                      child: Container(
                                        width: 100,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              Colors.white24,
                                              Colors.transparent,
                                            ],
                                            stops: [0.0, 0.5, 1.0],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          // Button content
                          Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: widget.buttonPadding,
                                vertical: widget.buttonPadding * 0.6,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: _iconScaleAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _iconScaleAnimation.value,
                                        child: Transform.rotate(
                                          angle: _isHovered
                                              ? 0.087
                                              : 0, // 5 degrees
                                          child: Text(
                                            widget.icon,
                                            style: TextStyle(
                                              fontSize: widget.iconSize,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(width: widget.buttonPadding * 0.3),
                                  Text(
                                    widget.text,
                                    style: TextStyle(
                                      fontSize: widget.iconSize * 0.8,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 扩展方法：将新难度等级转换为旧的枚举（用于兼容性）
extension AIDifficultyLevelExtension on AIDifficultyLevel {
  AIDifficulty _toOldDifficulty() {
    final result = level <= 3
        ? AIDifficulty.easy
        : (level <= 6 ? AIDifficulty.medium : AIDifficulty.hard);
    print(
        'AIDifficultyLevelExtension: ${displayName}(级别$level) -> ${result.name}');
    return result;
  }
}
