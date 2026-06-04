import 'dart:ui' show Offset;
import 'package:signals/signals_flutter.dart';
import '../polyline.dart';
import '../dtw.dart';
import '../scene/command.dart';
import '../scene/scene.dart';
import '../scene/animate.dart';

class Behavior {
  final FlutterSignal<SceneCommand> command;
  Scene dragStart(DragStart command, Scene scene) =>
      scene.copyWith(current: [...scene.current, command.position]);

  Scene dragEnd(DragEnd command, Scene scene) => scene.copyWith(
    previous: [...scene.previous, scene.current],
    current: [],
    misses: 0,
  );

  Behavior(this.command);
}

class StrokeByStroke extends Behavior {
  StrokeByStroke(super.command);

  void _animateStroke(Polyline current, Polyline stroke) {
    void callback(t) {
      Offset lerp(i) => Offset.lerp(current[i], stroke[i], t)!;
      final frame = List.generate(stroke.length, lerp);
      command.value = AnimationFrame([frame]);
    }

    void end() => command.value = AnimationEnd(stroke);
    animate(callback: callback, end: end);
  }

  @override
  Scene dragStart(DragStart command, Scene scene) => scene.copyWith(
    templateVisible: false,
    current: [...scene.current, command.position],
  );

  @override
  Scene dragEnd(DragEnd _, Scene scene) {
    final index = scene.previous.length;
    final stroke = scene.template[index];
    final current = resample(scene.current, stroke.length);

    final distance = PolylineDTW.compare(stroke, current);
    if (distance < 0.06) {
      _animateStroke(current, stroke);
      return scene.copyWith(
        previous: [...scene.previous, scene.template[index]],
        current: [],
        frame: [scene.current],
        misses: 0,
      );
    } else {
      // Reset; start over.
      return scene.copyWith(
        // previous: [],
        current: [],
        misses: scene.misses + 1,
      );
    }
  }
}
