import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:testflutter/widgets/privacy_content.dart';

class PrivacyDialog extends StatefulWidget {
  final FutureOr<void> Function() onAccept;
  final FutureOr<void> Function() onReject;

  const PrivacyDialog({super.key, required this.onAccept, required this.onReject});

  @override
  State<PrivacyDialog> createState() => _PrivacyDialogState();
}

class _PrivacyDialogState extends State<PrivacyDialog> {
  bool _loading = true;
  String? _error;
  List<Widget> _content = const [];

  static const _assetPath = 'assets/privacy/privacy.txt';

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
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
    final maxHeight = MediaQuery.of(context).size.height * 0.8;
    final maxWidth = MediaQuery.of(context).size.width * 0.9;

    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: maxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: const [
                    Icon(Icons.privacy_tip, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '隐私政策与用户协议',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _loading
                    ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                    : _error != null
                        ? _ErrorView(message: _error!, onRetry: _loadContent)
                        : Scrollbar(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _content,
                              ),
                            ),
                          ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () async {
                        await widget.onReject();
                      },
                      child: const Text('不同意并退出'),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _loading || _error != null ? null : () async {
                        await widget.onAccept();
                      },
                      child: const Text('同意并继续'),
                    ),
                  ],
                ),
              ),
            ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            )
          ],
        ),
      ),
    );
  }
}
