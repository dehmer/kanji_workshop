import 'package:flutter/material.dart';
import 'package:kanji_workshop/database.dart';

class KanjiInfo extends StatelessWidget {
  final KanjiInfoData data;
  KanjiInfo({required this.data});

  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 20.0,
      children: [
        Text(data.literal, style: TextStyle(fontSize: 80)),
        Column(
          children: [
            LimitedBox(
              maxWidth: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4.0,
                children: [
                  SizedBox(height: 16),
                  Text(
                    data.meaning,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    data.reading,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    data.strokes,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
