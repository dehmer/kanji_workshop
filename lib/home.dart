import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'kanji_draw.dart';
import 'kanji_info.dart';
import 'polyline.dart';
import 'database.dart';

const kankenLevel = 2;
const offWhite = Color(0xFFfefdfa);

Widget sizedBox({
  required double width,
  required double height,
  required Widget child,
}) => SizedBox(
  width: width,
  height: height,
  child: DecoratedBox(
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
    child: child,
  ),
);

class Home extends StatelessWidget {
  final literals = signal<List<String>>([]);
  final template = signal<PolylineList>(([]));
  final kanji = signal<KanjiData>((
    literal: '',
    meaning: '',
    reading: '',
    strokes: '',
  ));

  final composite = signal<List<CompositeData>>([]);

  Home({super.key}) {
    onNext();
  }

  void onNext() async {
    if (literals.value.isEmpty) {
      final literals = await DatabaseService.instance.randomKankenLiterals(
        kankenLevel,
      );
      this.literals.value = literals;
    }

    final [head, ...tail] = literals.value;
    literals.value = tail;
    template.value = await DatabaseService.instance.strokes(head);
    kanji.value = await DatabaseService.instance.info(head);
    composite.value = await DatabaseService.instance.composite(head);
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
        child: Flex(
          direction: direction,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            sizedBox(
              width: width,
              height: height,
              child: SignalBuilder(
                builder: (context) {
                  return KanjiInfo(data: kanji.value);
                },
              ),
            ),
            sizedBox(
              width: width,
              height: height,
              child: Column(
                children: [
                  SizedBox(height: 120),
                  SignalBuilder(
                    builder: (context) {
                      return KanjiDraw(
                        template: template.value,
                        onNext: onNext,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
