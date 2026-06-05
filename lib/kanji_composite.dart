import 'dart:math';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'repository.dart';

Matrix4 flipTransform(double value) {
  return Matrix4.identity()
    ..setEntry(3, 2, 0.004)
    ..rotateX(value);
}

final mirrorTransform = Matrix4.identity()..rotateX(pi);

class FrontCard extends StatelessWidget {
  final CompositeData data;
  const FrontCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SizedBox(height: 20),
          Text(data.reading, style: TextTheme.of(context).bodyMedium),
          Text(data.kanji, style: TextTheme.of(context).displaySmall),
        ],
      ),
    );
  }
}

class BackCard extends StatelessWidget {
  final CompositeData data;
  const BackCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: mirrorTransform,
      child: Card(
        child: SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: IgnorePointer(
              child: TextField(
                controller: TextEditingController()..text = data.meaning,
                maxLines: 4, // Set this
                readOnly: true,
                decoration: null,
                keyboardType: TextInputType.multiline,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CardContainer extends StatelessWidget {
  final CompositeData data;
  final ticker = tickerSignal();
  final duration = const Duration(milliseconds: 250);
  late final controller = ticker.toAnimationController(duration: duration);
  late final animation = Tween(begin: 0.0, end: pi).animate(controller);
  late final rotation = valueListenableToSignal(animation);
  late final isFront = computed(() => rotation.value < pi / 2.0);

  CardContainer({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => isFront.value ? controller.forward() : controller.reverse(),
      child: SignalBuilder(
        builder: (context) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Transform(
                alignment: Alignment.center,
                transform: flipTransform(rotation.value),
                child: child,
              );
            },
            child: isFront.value ? FrontCard(data: data) : BackCard(data: data),
          );
        },
      ),
    );
  }
}

class KanjiComposite extends StatelessWidget {
  final List<CompositeData> data;
  const KanjiComposite({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final crossAxisCount =
        MediaQuery.orientationOf(context) == Orientation.landscape ? 2 : 3;
    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisExtent: 140,
      children: List.generate(data.length, (index) {
        return CardContainer(data: data[index]);
      }),
    );
  }
}
