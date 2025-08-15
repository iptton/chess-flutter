import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:testflutter/widgets/privacy_content.dart';

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
    setState(() { _loading = true; _error = null; _content = const []; });
    try {
      final text = await rootBundle.loadString(_assetPath);
      if (text.trim().isEmpty) {
        throw Exception('隐私文本为空');
      }
      final widgets = PrivacyTextParser.buildWidgetsFromText(text);
      if (!mounted) return;
      setState(() { _content = widgets; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '无法加载隐私文本，请检查 $_assetPath 是否存在：$e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('隐私政策')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : Scrollbar(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _content),
                  ),
                ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('重试')),
        ]),
      ),
    );
  }
}
