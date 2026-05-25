import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:kanji_workshop/signal_extensions.dart';
import 'package:kanji_workshop/path_painter.dart';
import 'package:kanji_workshop/database.dart';
import 'package:kanji_workshop/vector.dart';
import 'package:kanji_workshop/scene.dart';

const kankenLevel = 4;
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
    if (t < 1.0)
      callback((t += 0.2).clamp(0.0, 1.0));
    else {
      timer.cancel();
      end();
    }
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

  // Optimization: Don't create strokePath on each Scene change,
  // extract strokes first.
  late final strokes = scene.map((scene) => scene.strokes);
  late final strokesPath = strokes.map(offsetsPath);
  late final path = computed(
    () => offsetsPath([...scene.value.previous, scene.value.current]),
  );

  late final previous = scene.map((scene) => scene.previous);
  late final previousPath = previous.map(offsetsPath);
  late final current = scene.map((scene) => scene.current);
  late final frame = scene.map((scene) => scene.frame);

  late final animationPath = computed(() {
    final stroke = frame.value.isNotEmpty ? frame.value : current.value;
    return offsetsPath([stroke]);
  });

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
                      painter: PathPainter(previousPath.watch(context), black),
                      size: Size.infinite,
                    ),
                    CustomPaint(
                      painter: PathPainter(animationPath.watch(context), black),
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
