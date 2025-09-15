import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/sound_service.dart';
import '../widgets/privacy_page.dart';
import '../widgets/themed_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _defaultHintMode = false;
  bool _soundEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final defaultHintMode = await SettingsService.getDefaultHintMode();
      final soundEnabled = await SettingsService.getSoundEnabled();
      setState(() {
        _defaultHintMode = defaultHintMode;
        _soundEnabled = soundEnabled;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSound(bool value) async {
    setState(() {
      _soundEnabled = value;
    });

    try {
      await SettingsService.setSoundEnabled(value);

      // 更新音效服务状态
      final soundService = SoundService();
      if (value) {
        await soundService.unmute();
      } else {
        await soundService.mute();
      }
    } catch (e) {
      // 如果保存失败，恢复原状态
      setState(() {
        _soundEnabled = !value;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('设置保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ThemedAppBar(
        title: '设置',
      ),
      body: ThemedBackground(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  ThemedCard(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text(
                            '音效',
                            style: TextStyle(color: AppTheme.primaryTextColor),
                          ),
                          subtitle: const Text(
                            '开启游戏音效（移动、胜利、失败等）',
                            style:
                                TextStyle(color: AppTheme.secondaryTextColor),
                          ),
                          value: _soundEnabled,
                          activeColor: AppTheme.primaryColor,
                          onChanged: _toggleSound,
                        ),
                        const Divider(),
                        SwitchListTile(
                          title: const Text(
                            '默认开启提示模式',
                            style: TextStyle(color: AppTheme.primaryTextColor),
                          ),
                          subtitle: const Text(
                            '新对局开始时自动开启提示模式',
                            style:
                                TextStyle(color: AppTheme.secondaryTextColor),
                          ),
                          value: _defaultHintMode,
                          activeColor: AppTheme.primaryColor,
                          onChanged: (bool value) async {
                            await SettingsService.setDefaultHintMode(value);
                            setState(() {
                              _defaultHintMode = value;
                            });
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(
                            Icons.security,
                            color: AppTheme.primaryColor,
                          ),
                          title: const Text(
                            '隐私政策',
                            style: TextStyle(color: AppTheme.primaryTextColor),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: AppTheme.secondaryTextColor,
                            size: 16,
                          ),
                          onTap: () async {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const PrivacyPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
