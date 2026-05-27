import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:kanji_workshop/signal_extensions.dart';
import 'package:kanji_workshop/scene_painter.dart';
import 'package:kanji_workshop/database.dart';
import 'package:kanji_workshop/scene/scene.dart';
import 'package:kanji_workshop/scene/command.dart';
import 'package:kanji_workshop/scene/behavior.dart';

const kankenLevel = 2;
const double canvasDimension = 150.0;

class Home extends StatelessWidget {
  final literals = signal<List<String>>([]);
  final command = signal<SceneCommand>(NullCommand());

  late final scene = loop<Scene, SceneCommand>(
    command,
    (acc, command) => acc.reduce(command),
    Scene(behavior: IndividualStrokes(command)),
  );

  Home({super.key}) {
    onNext();
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
