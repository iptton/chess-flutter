import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
class WebPage extends StatefulWidget {
  final String initialUrl;

  const WebPage({super.key, required this.initialUrl});

  @override
  State<WebPage> createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("隐私政策"),
      ),
      body:InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri.uri(Uri.parse("https://chess.pan2017.cn/?privacy"))),
      ),
    );
  }
}