import 'package:flutter/material.dart';
import 'package:tategaki/tategaki.dart';
import 'database.dart';

String formatReading(String reading) {
  return reading
      .split('、')
      .where((s) => !s.contains('-'))
      .map((s) => s.contains('.') ? '${s.replaceAll('.', '(')})' : s)
      .toList()
      .join('\n');
}

class KanjiInfo extends StatelessWidget {
  final KanjiData data;
  const KanjiInfo({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 0, 0),
            child: Text(
              data.meaning,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: Text(data.literal, style: TextStyle(fontSize: 80)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 0, 0),
            child: Text(data.strokes, style: TextStyle(fontSize: 16)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 0, 0),
            child: VerticalText(
              formatReading(data.reading),
              style: const VerticalTextStyle(
                baseStyle: TextStyle(fontSize: 20),
                characterSpacing: 4,
                lineSpacing: 10,
              ),
              maxHeight: 150,
            ),
          ),
        ],
      ),
    );
  }
}
