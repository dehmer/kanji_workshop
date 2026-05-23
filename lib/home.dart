import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'signal_extensions.dart';
import 'path_painter.dart';
import 'database.dart';
import 'vector.dart';
import 'dtw.dart';
import 'option.dart';

const kankenLevel = 3;
const strokeWidth = 5.0;
const double canvasDimension = 150;
const scale = canvasDimension / vgDimension;

final black = Paint()
  ..style = PaintingStyle.stroke
  ..color = Colors.black
  ..strokeWidth = strokeWidth
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

final gray = Paint.from(black)..color = Color(0xffd0d0d0);
final red = Paint.from(black)..color = Color(0xffff0000);
final blue = Paint.from(black)..color = Color.fromARGB(255, 110, 133, 237);

typedef LerpCallback = Polyline Function(double t);
typedef EndCallback = Polyline Function();

class Animation {
  final FlutterSignal<Polyline> target;
  double t = 0;

  Animation(this.target);

  void start({required LerpCallback callback, required EndCallback end}) {
    Timer.periodic(Duration(milliseconds: 16), (timer) {
      target.value = callback(t);
      t += 0.2;
      if (t >= 1) {
        timer.cancel();
        t = 0;
        target.value = end();
      }
    });
  }
}

({FlutterSignal<Option<T>> signal, void Function(T) callback}) listen<T>() {
  final signal = FlutterSignal<Option<T>>(None());
  void callback(T event) => signal.value = Some(event);
  return (signal: signal, callback: callback);
}

class Home extends StatelessWidget {
  final lerpSignal = signal<Polyline>([]);
  late final lerpPath = lerpSignal.map((stroke) => offsetsPath([stroke]));
  late final animation = Animation(lerpSignal);

  final pool = signal<List<String>>([]);
  final templatePolylineList = signal<PolylineList>([]);
  late final templatePath = templatePolylineList.map(offsetsPath);
  final previous = signal<PolylineList>([]);
  final current = signal<Polyline>([]);
  final currentPaint = Signal<Paint>(black);

  late final path = computed(
    () => offsetsPath([...previous.value, current.value]),
  );

  final dragStart = listen<DragStartDetails>();
  final dragUpdate = listen<DragUpdateDetails>();
  final dragEnd = listen<DragEndDetails>();

  Home({super.key}) {
    onNext();

    effect(() {
      print(dragStart.signal.value);
    });
  }

  void onPanStart(DragStartDetails details) {
    if (currentPaint.value == black) {
      current.value = [details.localPosition];
    }
  }

  void onPanUpdate(DragUpdateDetails details) {
    // TODO: handle localPosition outside Container bounds

    if (currentPaint.value == blue) {
      return;
    }

    // Optimization - Discard position if same as last.
    if (current.value.isEmpty) {
      current.value = [...current.value, details.localPosition];
    } else if (current.value.last != details.localPosition) {
      current.value = [...current.value, details.localPosition];
    } else {
      // Drop duplicate position.
    }
  }

  void onPanEnd(DragEndDetails details) {
    if (currentPaint.value == blue) {
      onNext();
      return;
    }

    final index = previous.value.length;
    final a = templatePolylineList.value[index];
    final b = current.value;

    final c = resample(b, a.length);
    final distance = PolylineDTW.compare(
      a,
      c,
      directionWeight: 0.7,
      resampleCount: 48,
      normalize: true,
    );

    if (distance < 10) {
      current.value = [];
      animation.start(
        callback: (t) {
          return List.generate(a.length, (i) {
            return Offset.lerp(c[i], a[i], t.clamp(0.0, 1.0))!;
          });
        },
        end: () {
          previous.value = [...previous.value, a];
          if (previous.value.length == templatePolylineList.value.length) {
            currentPaint.value = blue;
          }
          return [];
        },
      );
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
    final strokes = await DatabaseService.instance.strokes(
      head,
      targetDimension: canvasDimension,
    );

    templatePolylineList.value = strokes;
    previous.value = [];
    current.value = [];
    currentPaint.value = black;
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
              // onPanStart: dragStart.callback,
              // onPanUpdate: dragUpdate.callback,
              // onPanEnd: dragEnd.callback,
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
                      painter: PathPainter(
                        path.watch(context),
                        currentPaint.watch(context),
                      ),
                      size: Size.infinite,
                    ),
                    CustomPaint(
                      painter: PathPainter(lerpPath.watch(context), black),
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
