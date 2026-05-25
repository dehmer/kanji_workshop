import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'signal_extensions.dart';
import 'path_painter.dart';
import 'database.dart';
import 'vector.dart';
import 'scene.dart';

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

typedef LerpCallback = void Function(double t);
typedef VoidFunction = void Function();

void animate({required LerpCallback callback, required VoidFunction end}) {
  var t = 0.0;
  Timer.periodic(Duration(milliseconds: 16), (timer) {
    while (t < 1.0) callback((t += 0.2).clamp(0.0, 1.0));
    timer.cancel();
    end();
  });
}

class Home extends StatelessWidget {
  final literals = signal<List<String>>([]);
  final command = signal<SceneCommand>(NullCommand());

  late final scene = loop<Scene, SceneCommand>(
    command,
    (acc, command) => acc.reduce(command),
    Scene(onMatch: onMatch),
  );

  late final strokesPath = computed(() => offsetsPath(scene.value.strokes));

  late final path = computed(
    () => offsetsPath([...scene.value.previous, scene.value.current]),
  );

  late final animationFrame = computed(() => offsetsPath([scene.value.frame]));

  Home({super.key}) {
    onNext();
  }

  void onMatch(Polyline current, Polyline stroke) {
    void callback(t) {
      Offset lerp(i) => Offset.lerp(current[i], stroke[i], t)!;
      final frame = List.generate(stroke.length, lerp);
      command.value = AnimationFrame(frame);
    }

    void end() => command.value = AnimationEnd(stroke);
    animate(callback: callback, end: end);
  }

  void onPanStart(DragStartDetails details) =>
      command.value = DragStart(details.localPosition);

  void onPanUpdate(DragUpdateDetails details) =>
      command.value = DragUpdate(details.localPosition);

  void onPanEnd(DragEndDetails details) =>
      command.value = DragEnd(details.localPosition);

  void onNext() async {
    if (this.literals.value.isEmpty) {
      final literals = await DatabaseService.instance.randomKankenLiterals(
        kankenLevel,
      );
      this.literals.value = literals;
    }

    final [head, ...tail] = this.literals.value;
    this.literals.value = tail;
    final strokes = await DatabaseService.instance.strokes(
      head,
      targetDimension: canvasDimension,
    );

    command.value = Initialize(strokes);
  }

  void onClear() => command.value = Reset();

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
                      painter: PathPainter(strokesPath.watch(context), gray),
                      size: Size.infinite,
                    ),
                    CustomPaint(
                      painter: PathPainter(path.watch(context), black),
                      size: Size.infinite,
                    ),
                    CustomPaint(
                      painter: PathPainter(
                        animationFrame.watch(context),
                        black,
                      ),
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
