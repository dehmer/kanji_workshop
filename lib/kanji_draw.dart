import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:signals/signals_flutter.dart';
import 'extensions/signal_extensions.dart';
import 'polyline.dart';
import 'scene_painter.dart';
import 'scene/scene.dart';

const double canvasDimension = 110.0;
const double buttonSize = 30.0;
Offset scalePosition(Offset position) => position / canvasDimension;

class KanjiDraw extends StatelessWidget {
  final String literal;
  final PolylineList template;
  final void Function() onNext;

  final feed = signal<SceneCommand>(NullCommand());
  late final scene = loop<Scene, SceneCommand>(
    feed,
    (acc, command) => acc.reduce(command),
    Scene(
      feed: feed,
      literal: literal,
      scalePosition: scalePosition,
      target: template,
    ),
  );

  late final templateVisible = scene.map((scene) => scene.targetVisible);
  late final gridVisible = scene.map((scene) => scene.gridVisible);

  KanjiDraw({
    super.key,
    required this.literal,
    required this.template,
    required this.onNext,
  });

  void onPointer(PointerEvent event) {
    feed.value = Event(event);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Listener(
            onPointerDown: onPointer,
            onPointerMove: onPointer,
            onPointerUp: onPointer,
            child: Container(
              width: canvasDimension,
              height: canvasDimension,
              decoration: BoxDecoration(
                color: Colors.white70,
                border: Border.all(color: Colors.black12, width: 2.0),
              ),
              child: RepaintBoundary(
                child: SignalBuilder(
                  builder: (context) {
                    return CustomPaint(
                      painter: ScenePainter(scene.value, canvasDimension),
                      size: Size.infinite,
                    );
                  },
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
                  onPressed: () => feed.value = Reset(),
                  child: Icon(
                    CupertinoIcons.restart,
                    color: Colors.pink,
                    size: buttonSize,
                  ),
                ),
                CupertinoButton(
                  onPressed: onNext,
                  child: Icon(
                    CupertinoIcons.forward,
                    color: Colors.pink,
                    size: buttonSize,
                  ),
                ),
                CupertinoButton(
                  onPressed: () => feed.value = ToggleTarget(),
                  child: SignalBuilder(
                    builder: (context) {
                      return Icon(
                        templateVisible.value
                            ? CupertinoIcons.eye
                            : CupertinoIcons.eye_slash,
                        color: Colors.pink,
                        size: buttonSize,
                      );
                    },
                  ),
                ),
                CupertinoButton(
                  onPressed: () => feed.value = ToggleGrid(),
                  child: SignalBuilder(
                    builder: (context) {
                      return Icon(
                        gridVisible.value
                            ? CupertinoIcons.square_grid_2x2_fill
                            : CupertinoIcons.square_grid_2x2,
                        color: Colors.pink,
                        size: buttonSize,
                      );
                    },
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
