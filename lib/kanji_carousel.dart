import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'repository.dart';
import 'kanji_info.dart';
import 'kanji_composite.dart';

typedef SliderData = ({KanjiData kanji, List<CompositeData> composite});

class KanjiCarousel extends StatelessWidget {
  final KanjiData? kanjiInfo;
  final List<CompositeData> kanjiComposite;
  final CarouselSliderController controller = CarouselSliderController();

  KanjiCarousel({
    super.key,
    required this.kanjiInfo,
    required this.kanjiComposite,
  });

  @override
  Widget build(BuildContext context) {
    final children = [
      KanjiInfo(data: kanjiInfo),
      KanjiComposite(data: kanjiComposite),
    ];

    return CarouselSlider(
      carouselController: controller,
      items: children,
      options: CarouselOptions(viewportFraction: 1.0, autoPlay: false),
    );
  }
}
