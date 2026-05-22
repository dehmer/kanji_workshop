import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'path_painter.dart';
import 'database.dart';
import 'vector.dart';
import 'dtw.dart';
import 'signal_extensions.dart';

const kankenLevel = 1;

const strokeWidth = 6.0;

final black = Paint()
  ..style = PaintingStyle.stroke
  ..color = Colors.black
  ..strokeWidth = strokeWidth
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

final gray = Paint.from(black)..color = Color(0xffd0d0d0);
final red = Paint.from(black)..color = Color(0xffff0000);

const double canvasDimension = 180;
const scale = canvasDimension / vgDimension;

typedef LerpCallback = Polyline Function(double t);
typedef EndCallback = Polyline Function();

class Animation {
  final FlutterSignal<Polyline> target;
  double t = 0;

  Animation(this.target);

  void start({required LerpCallback callback, required EndCallback end}) {
    Timer.periodic(Duration(milliseconds: 20), (timer) {
      target.value = callback(t);
      t += 0.1;
      if (t > 1) {
        timer.cancel();
        t = 0;
        target.value = end();
      }
    });
  }
}

class Listener<T> extends FlutterSignal<T> {
  void callback(T value) {
    this.value = value;
  }

  Listener(super.internalValue, {super.autoDispose, super.debugLabel});
}

class Home extends StatelessWidget {
  Home({super.key}) {
    onNext();
  }

  final lerpSignal = signal<Polyline>([]);
  late final lerpPath = lerpSignal.map((stroke) => offsetsPath([stroke]));
  late final timer = Animation(lerpSignal);

  final pool = signal<List<String>>([]);
  final templatePolylineList = signal<PolylineList>([]);
  late final templatePath = templatePolylineList.map(offsetsPath);
  final previous = signal<PolylineList>([]);
  final current = signal<Polyline>([]);

  late final path = computed(
    () => offsetsPath([...previous.value, current.value]),
  );

  void onPanStart(DragStartDetails details) {
    current.value = [details.localPosition];
  }

  void onPanUpdate(DragUpdateDetails details) {
    // TODO: handle localPosition outside Container bounds
    // Optimization - Discard position if same as last
    final index = current.value.length - 1;
    if (current.value.isEmpty ||
        current.value[index] != details.localPosition) {
      current.value = [...current.value, details.localPosition];
    }
  }

  void onPanEnd(DragEndDetails details) {
    final index = previous.value.length;
    final a = templatePolylineList.value[index];
    final b = current.value;
    final distance = PolylineDTW.compare(
      a,
      b,
      directionWeight: 0.7,
      resampleCount: 48,
      normalize: true,
    );

    if (distance < 8) {
      previous.value = [...previous.value, current.value];
      current.value = [];

      if (previous.value.length == templatePolylineList.value.length) {
        previous.value = [];
        onNext();
      }
    } else {
      current.value = [];
      previous.value = [];
    }
  }

  void onNext() async {
    if (pool.value.isEmpty) {
      final literals = await DatabaseService.instance.randomKankenLiterals(
        kankenLevel,
      );
      pool.value = literals;
    }

    final [head, ...tail] = pool.value;
    pool.value = tail;
    final strokes = await DatabaseService.instance.strokes(head);
    templatePolylineList.value = strokes;
    previous.value = [];
    current.value = [];
  }

  void onClear() {
    previous.value = [];
    current.value = [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryFixed,
        title: Text('Kanji Workshop'),
      ),

      body: Center(
        child: Column(
          children: [
            SizedBox(height: 150),
            GestureDetector(
              onPanStart: onPanStart,
              onPanUpdate: onPanUpdate,
              onPanEnd: onPanEnd,
              child: Container(
                width: canvasDimension,
                height: canvasDimension,
                decoration: BoxDecoration(
                  color: Colors.white70,
                  border: Border.all(color: Colors.black12, width: 2.0),
                ),
                child: Stack(
                  children: [
                    CustomPaint(
                      painter: PathPainter(templatePath.watch(context), gray),
                      size: Size.infinite,
                    ),
                    CustomPaint(
                      painter: PathPainter(path.watch(context), black),
                      size: Size.infinite,
                    ),
                    CustomPaint(
                      painter: PathPainter(lerpPath.watch(context), red),
                      size: Size.infinite,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: onNext, child: Text("Next")),
                SizedBox(width: 40),
                ElevatedButton(onPressed: onClear, child: Text("Clear")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
