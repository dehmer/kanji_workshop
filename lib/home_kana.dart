import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:kanji_workshop/literals.dart';
import 'package:kanji_workshop/kana.dart';
import 'package:signals/signals_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
// import 'package:flutter/cupertino.dart' show CupertinoSlider;
import 'extensions/signal_extensions.dart';
import 'kanji_draw.dart';
import 'kanji_carousel.dart';
import 'polyline.dart';
import 'repository.dart';

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

Future<PolylineList> loadStrokes(String literal) async {
  final repository = await Repository.getInstance();
  return repository.strokes(literal);
}

Future<KanjiData?> loadInfo(String literal) async {
  final repository = await Repository.getInstance();
  return repository.info(literal);
}

Future<List<CompositeData>> loadComposite(String literal) async {
  final repository = await Repository.getInstance();
  return repository.composite(literal);
}

class Home extends StatelessWidget {
  // final command = signal<LiteralsCommand>(NullCommand());
  final command = signal<KanaCommand>(NullCommand());
  late final literals = loop<Kana, KanaCommand>(
    command,
    (acc, command) => acc.reduce(command),
    Kana(),
  );

  late final literal = literals.map((pool) => pool.current);

  late final template = asyncMap<String, PolylineList>(
    literal,
    loadStrokes,
    [],
  );

  late final kanjiInfo = asyncMap(literal, loadInfo, (
    literal: '',
    meaning: '',
    reading: '',
    strokes: '',
  ));

  late final kanjiComposite = asyncMap<String, List<CompositeData>>(
    literal,
    loadComposite,
    [],
  );

  final CarouselSliderController controller = CarouselSliderController();

  Home({super.key}) {
    command.value = InitializeKana();
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
                builder: (context) => KanjiCarousel(
                  kanjiInfo: kanjiInfo.value,
                  kanjiComposite: kanjiComposite.value,
                ),
              ),
            ),
            sizedBox(
              width: width,
              height: height,
              child: Column(
                children: [
                  SizedBox(height: 40),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SignalBuilder(
                      //   builder: (context) {
                      //     final level = literals.value.level;
                      //     final count = literals.value.count;
                      //     final remaining = literals.value.remaining.length;
                      //     return Padding(
                      //       padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                      //       child: Text(
                      //         'Kanji Kentei Level: $level [$remaining/$count]',
                      //       ),
                      //     );
                      //   },
                      // ),
                      // SizedBox(height: 20),
                      // SizedBox(
                      //   width: width * 0.8,
                      //   child: SignalBuilder(
                      //     builder: (context) {
                      //       final value = kankenIndex(literals.value.level);
                      //       return CupertinoSlider(
                      //         min: 0,
                      //         max: 11,
                      //         value: value.toDouble(),
                      //         divisions: 12,
                      //         onChanged: (value) {
                      //           final level = kankenLevel(
                      //             value.round().toInt(),
                      //           );
                      //           command.value = Initialize(level);
                      //         },
                      //       );
                      //     },
                      //   ),
                      // ),
                    ],
                  ),
                  SizedBox(height: 80),
                  SignalBuilder(
                    builder: (context) {
                      return KanjiDraw(
                        literal: literal.value,
                        template: template.value,
                        onNext: () => command.value = NextKana(),
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
