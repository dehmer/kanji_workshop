import 'dart:ui' show Offset;
import 'package:signals/signals_flutter.dart';
import 'package:kanji_workshop/polyline.dart';
import 'package:kanji_workshop/dtw.dart';
import 'package:kanji_workshop/scene/command.dart';
import 'package:kanji_workshop/scene/scene.dart';
import 'package:kanji_workshop/scene/animate.dart';

class Behavior {
  final FlutterSignal<SceneCommand> command;
  Scene dragStart(DragStart command, Scene scene) =>
      scene.copyWith(current: [...scene.current, command.position]);

  Scene dragEnd(DragEnd command, Scene scene) =>
      scene.copyWith(previous: [...scene.previous, scene.current], current: []);

  Behavior(this.command);
}

class StrokeByStroke extends Behavior {
  StrokeByStroke(super.command);

  void _animateStroke(Polyline current, Polyline stroke) {
    void callback(t) {
      Offset lerp(i) => Offset.lerp(current[i], stroke[i], t)!;
      final frame = List.generate(stroke.length, lerp);
      command.value = AnimationFrame(frame);
    }

    void end() => command.value = AnimationEnd(stroke);
    animate(callback: callback, end: end);
  }

  Scene dragEnd(DragEnd _, Scene scene) {
    final index = scene.previous.length;
    final stroke = scene.template[index];
    final current = resample(scene.current, stroke.length);

    final distance = PolylineDTW.compare(stroke, current);
    if (distance < 0.06) {
      _animateStroke(current, stroke);
      return scene.copyWith(current: []);
    } else {
      // Reset; start over.
      return scene.copyWith(previous: [], current: []);
    }
  }
}
