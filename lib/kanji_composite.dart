import 'package:flutter/material.dart';
import 'package:kanji_workshop/database.dart';

class KanjiComposite extends StatelessWidget {
  final List<CompositeData> data;
  const KanjiComposite({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    print(data);
    return Container();
  }
}
