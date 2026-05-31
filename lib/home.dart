import 'package:flutter/material.dart';
import 'package:kanji_workshop/kanji_draw.dart';
import 'package:kanji_workshop/kanji_info.dart';
import 'package:signals/signals_flutter.dart';
import 'package:kanji_workshop/polyline.dart';
import 'package:kanji_workshop/database.dart';

const kankenLevel = 1;
const offWhite = const Color(0xFFfefdfa);

Widget sizedBox({
  required double width,
  required double height,
  required Widget child,
}) => SizedBox(
  width: width,
  height: height,
  child: DecoratedBox(
    child: child,
    decoration: BoxDecoration(
      color: offWhite,
      boxShadow: [
        BoxShadow(
          color: Color(0x80808080),
          blurRadius: 3.0,
          blurStyle: BlurStyle.outer,
        ),
      ],
    ),
  ),
);

class Home extends StatelessWidget {
  final literals = signal<List<String>>([]);
  final template = signal<PolylineList>(([]));
  final kanjiInfo = signal<KanjiInfoData>((
    literal: '',
    meaning: '',
    reading: '',
    strokes: '',
  ));

  Home({super.key}) {
    onNext();
  }

  void onNext() async {
    if (this.literals.value.isEmpty) {
      final literals = await DatabaseService.instance.randomKankenLiterals(
        kankenLevel,
      );
      this.literals.value = literals;
    }

    final [head, ...tail] = this.literals.value;
    this.literals.value = tail;
    final strokes = await DatabaseService.instance.strokes(head);
    template.value = strokes;

    final info = await DatabaseService.instance.info(head);
    kanjiInfo.value = info;
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.orientationOf(context);
    final size = MediaQuery.sizeOf(context);

    final direction = orientation == Orientation.portrait
        ? Axis.vertical
        : Axis.horizontal;
    final width = orientation == Orientation.portrait
        ? size.width * 0.7
        : size.height * 0.5;
    final height = orientation == Orientation.portrait
        ? size.height * 0.35
        : size.width * 0.4;

    return Scaffold(
      backgroundColor: offWhite,
      appBar: AppBar(backgroundColor: offWhite, title: Text('Kanji Workshop')),
      body: Center(
        child: Container(
          child: Flex(
            direction: direction,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              sizedBox(
                width: width,
                height: height,
                child: KanjiInfo(data: kanjiInfo.watch(context)),
              ),
              sizedBox(
                width: width,
                height: height,
                child: Column(
                  children: [
                    SizedBox(height: 120),
                    KanjiDraw(
                      template: template.watch(context),
                      onNext: onNext,
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
