import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:kanji_workshop/signal_extensions.dart';
import 'package:kanji_workshop/scene_painter.dart';
import 'package:kanji_workshop/database.dart';
import 'package:kanji_workshop/polyline.dart';
import 'package:kanji_workshop/scene.dart';

const kankenLevel = 2;
const double canvasDimension = 150.0;

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

  // Forward drag events to scene.

  void onPanStart(DragStartDetails details) =>
      command.value = DragStart(details.localPosition / canvasDimension);

  void onPanUpdate(DragUpdateDetails details) =>
      command.value = DragUpdate(details.localPosition / canvasDimension);

  void onPanEnd(DragEndDetails details) =>
      command.value = DragEnd(details.localPosition / canvasDimension);

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
    command.value = Initialize(strokes);
  }

  void onClear() => command.value = Reset();

  void onToggleTemplate() =>
      command.value = ShowTemplate(!scene.value.templateVisible);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfefdfa),
      appBar: AppBar(
        backgroundColor: const Color(0xFFfefdfa),
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
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: ScenePainter(
                      scene.watch(context),
                      canvasDimension,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: onNext, child: Text("Next")),
                SizedBox(width: 20),
                ElevatedButton(onPressed: onClear, child: Text("Clear")),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: onToggleTemplate,
                  child: Text("Template"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
