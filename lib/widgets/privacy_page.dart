import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:testflutter/widgets/privacy_content.dart';
import 'package:testflutter/widgets/themed_background.dart';
import 'dart:ui';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  static const _assetPath = 'assets/privacy/privacy.txt';
  bool _loading = true;
  String? _error;
  List<Widget> _content = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _content = const [];
    });
    try {
      final text = await rootBundle.loadString(_assetPath);
      if (text.trim().isEmpty) {
        throw Exception('隐私文本为空');
      }
      final widgets = PrivacyTextParser.buildWidgetsFromText(text);
      if (!mounted) return;
      setState(() {
        _content = widgets;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '无法加载隐私文本，请检查 $_assetPath 是否存在：$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 768;
    final maxWidth = isSmallScreen ? double.infinity : 800.0;

    return Scaffold(
      appBar: const ThemedAppBar(title: '隐私政策'),
      body: ThemedBackground(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            margin: const EdgeInsets.all(16),
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryColor))
                : _error != null
                    ? _ErrorView(message: _error!, onRetry: _load)
                    : ThemedCard(
                        child: Scrollbar(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _content,
                            ),
                          ),
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ThemedCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppTheme.secondaryTextColor,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.secondaryTextColor,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ThemedButton(
                text: '重试',
                icon: Icons.refresh,
                onPressed: onRetry,
                isSecondary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
