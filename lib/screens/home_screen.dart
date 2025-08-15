import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'game_screen.dart';
import 'replay_screen.dart';
import 'settings_screen.dart';
import 'package:testflutter/widgets/privacy_dialog.dart' as privacy;
import '../services/privacy_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const GameScreen(),
    const ReplayScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensurePrivacyAccepted());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports),
            label: '对战',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '复盘',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}