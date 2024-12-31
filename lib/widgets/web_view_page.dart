import 'package:flutter/material.dart';
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
        title: const Text("WebView"),
      ),
      body:Text("WebView"),
    );
  }
}