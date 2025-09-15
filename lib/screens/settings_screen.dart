import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../widgets/privacy_page.dart';
import '../widgets/themed_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _defaultHintMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final defaultHintMode = await SettingsService.getDefaultHintMode();
    setState(() {
      _defaultHintMode = defaultHintMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ThemedAppBar(
        title: '设置',
      ),
      body: ThemedBackground(
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            ThemedCard(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      '默认开启提示模式',
                      style: TextStyle(color: AppTheme.primaryTextColor),
                    ),
                    subtitle: const Text(
                      '新对局开始时自动开启提示模式',
                      style: TextStyle(color: AppTheme.secondaryTextColor),
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
