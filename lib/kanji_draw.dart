import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:signals/signals_flutter.dart';
import 'package:kanji_workshop/signal_extensions.dart';
import 'package:kanji_workshop/polyline.dart';
import 'package:kanji_workshop/scene_painter.dart';
import 'package:kanji_workshop/scene/scene.dart';
import 'package:kanji_workshop/scene/command.dart';
import 'package:kanji_workshop/scene/behavior.dart';

const double canvasDimension = 150.0;
const double buttonSize = 30.0;

class KanjiDraw extends StatelessWidget {
  final PolylineList template;
  final void Function() onNext;

  final command = signal<SceneCommand>(NullCommand());
  late final behavior = Behavior(command);
  late final scene = loop<Scene, SceneCommand>(
    command,
    (acc, command) => acc.reduce(command),
    Scene(template: template, behavior: StrokeByStroke(command)),
  );

  late final templateVisible = scene.map((scene) => scene.templateVisible);
  late final gridVisible = scene.map((scene) => scene.gridVisible);

  KanjiDraw({required this.template, required this.onNext});

  // Forward drag events to scene.

  void onPanStart(DragStartDetails details) =>
      command.value = DragStart(details.localPosition / canvasDimension);

  void onPanUpdate(DragUpdateDetails details) =>
      command.value = DragUpdate(details.localPosition / canvasDimension);

  void onPanEnd(DragEndDetails details) =>
      command.value = DragEnd(details.localPosition / canvasDimension);

  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
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
                  painter: ScenePainter(scene.watch(context), canvasDimension),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoButton(
                  onPressed: () => command.value = Reset(),
                  child: Icon(
                    CupertinoIcons.restart,
                    color: Colors.pink,
                    size: buttonSize,
                  ),
                ),
                // SizedBox(width: 10),
                CupertinoButton(
                  onPressed: onNext,
                  child: Icon(
                    CupertinoIcons.forward,
                    color: Colors.pink,
                    size: buttonSize,
                  ),
                ),
                // SizedBox(width: 10),
                CupertinoButton(
                  onPressed: () => command.value = ToggleTemplate(),
                  child: Icon(
                    templateVisible.watch(context)
                        ? CupertinoIcons.eye
                        : CupertinoIcons.eye_slash,
                    color: Colors.pink,
                    size: buttonSize,
                  ),
                ),
                // SizedBox(width: 10),
                CupertinoButton(
                  onPressed: () => command.value = ToggleGrid(),
                  child: Icon(
                    gridVisible.watch(context)
                        ? CupertinoIcons.square_grid_2x2_fill
                        : CupertinoIcons.square_grid_2x2,
                    color: Colors.pink,
                    size: buttonSize,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
