import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../widgets/web_view_page.dart';

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
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('默认开启提示模式'),
            subtitle: const Text('新对局开始时自动开启提示模式'),
            value: _defaultHintMode,
            onChanged: (bool value) async {
              await SettingsService.setDefaultHintMode(value);
              setState(() {
                _defaultHintMode = value;
              });
            },
          ),
          // 隐私政策设置项
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('隐私政策'),
            onTap: () async {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WebPage(initialUrl: "https://chess.pan2017.cn/?privacy")),
              );
            },
          ),
          // 其他设置项...
        ],
      ),
    );
  }
}