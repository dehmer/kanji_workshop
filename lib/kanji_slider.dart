import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'repository.dart';
import 'kanji_info.dart';
import 'kanji_composite.dart';

typedef SliderData = ({KanjiData kanji, List<CompositeData> composite});

class KanjiSlider extends StatelessWidget {
  final SliderData data;
  final CarouselSliderController controller = CarouselSliderController();

  KanjiSlider({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final children = [
      KanjiInfo(data: data.kanji),
      KanjiComposite(data: data.composite),
    ];

    return CarouselSlider(
      carouselController: controller,
      items: children,
      options: CarouselOptions(viewportFraction: 1.0, autoPlay: false),
    );
  }
}
