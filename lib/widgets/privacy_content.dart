import 'package:flutter/material.dart';

class PrivacyTextParser {
  static List<Widget> buildWidgetsFromText(String text) {
    final lines = text.replaceAll('\r\n', '\n').split('\n');
    final children = <Widget>[];

    final buffer = StringBuffer();
    void flushParagraph() {
      final para = buffer.toString().trim();
      if (para.isNotEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(para, style: const TextStyle(fontSize: 14, height: 1.5)),
          ),
        );
      }
      buffer.clear();
    }

    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) { flushParagraph(); continue; }

      // 标题（# / ## / ###）
      if (RegExp(r'^#{1,3}\s').hasMatch(line)) {
        flushParagraph();
        int level = 0; while (level < line.length && line[level] == '#') { level++; }
        final title = line.replaceFirst(RegExp(r'^#{1,3}\s*'), '');
        final size = level == 1 ? 20.0 : (level == 2 ? 18.0 : 16.0);
        final weight = level == 1 ? FontWeight.w700 : FontWeight.w600;
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(title, style: TextStyle(fontSize: size, fontWeight: weight)),
          ),
        );
        continue;
      }

      // 列表（数字. 或 - / •）
      if (RegExp(r'^(\d+\.|[-•])\s').hasMatch(line)) {
        flushParagraph();
        final m = RegExp(r'^(\d+\.|[-•])\s').firstMatch(line)!;
        final bullet = m.group(1)!;
        final content = line.substring(m.group(0)!.length);
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$bullet ', style: const TextStyle(fontSize: 14)),
                Expanded(child: Text(content.trimLeft(), style: const TextStyle(fontSize: 14, height: 1.5))),
              ],
            ),
          ),
        );
        continue;
      }

      // 普通段落
      buffer.writeln(line);
    }

    flushParagraph();
    if (children.isEmpty) {
      children.add(Text(text, style: const TextStyle(fontSize: 14, height: 1.5)));
    }
    return children;
  }
}

