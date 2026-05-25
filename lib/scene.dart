import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:kanji_workshop/dtw.dart';
import 'package:kanji_workshop/vector.dart';

sealed class SceneCommand {}

class NullCommand extends SceneCommand {}

class Initialize extends SceneCommand {
  final PolylineList strokes;
  Initialize(this.strokes);
}

class Reset extends SceneCommand {}

class DragStart extends SceneCommand {
  final Offset position;
  DragStart(this.position);
}

class DragUpdate extends SceneCommand {
  final Offset position;
  DragUpdate(this.position);
}

class DragEnd extends SceneCommand {
  final Offset position;
  DragEnd(this.position);
}

class AnimationFrame extends SceneCommand {
  final Polyline frame;
  AnimationFrame(this.frame);
}

class AnimationEnd extends SceneCommand {
  final Polyline current;
  AnimationEnd(this.current);
}

@immutable
class Scene {
  final void Function(Polyline, Polyline) onMatch;
  final PolylineList strokes;
  final PolylineList template;
  final PolylineList previous;
  final Polyline current;
  final Polyline frame;

  const Scene({
    required this.onMatch,
    PolylineList? strokes,
    PolylineList? template,
    PolylineList? previous,
    Polyline? current,
    Polyline? frame,
  }) : strokes = strokes ?? const [],
       template = template ?? const [],
       previous = previous ?? const [],
       current = current ?? const [],
       frame = frame ?? const [];

  Scene copyWith({
    PolylineList? strokes,
    PolylineList? template,
    PolylineList? previous,
    Polyline? current,
    Polyline? frame,
  }) => Scene(
    onMatch: this.onMatch,
    strokes: strokes ?? this.strokes,
    template: template ?? this.template,
    previous: previous ?? this.previous,
    current: current ?? this.current,
    frame: frame ?? this.frame,
  );

  Scene reduce(SceneCommand command) => switch (command) {
    Initialize() => initialize(command),
    DragStart(position: final p) => copyWith(current: [...current, p]),
    DragUpdate(position: final p) => copyWith(current: [...current, p]),
    DragEnd() => dragEnd(command),
    Reset() => copyWith(previous: [], current: []),
    AnimationFrame(frame: final f) => copyWith(frame: f),
    AnimationEnd() => animationEnd(command),
    NullCommand() => this,
  };

  Scene initialize(Initialize command) {
    return copyWith(
      strokes: command.strokes,
      previous: [],
      current: [],
      frame: [],
    );
  }

  Scene dragEnd(DragEnd _) {
    final index = previous.length;
    final stroke = strokes[index];
    final current = resample(this.current, stroke.length);
    final directionWeight = 0.5;
    final distance = PolylineDTW.compare(
      stroke,
      current,
      directionWeight: directionWeight,
    );

    if (distance < 10.0) {
      onMatch(current, stroke);
      return copyWith(current: []);
    } else {
      // Reset attempt.
      return copyWith(previous: [], current: []);
    }
  }

  Scene animationEnd(AnimationEnd command) {
    return copyWith(previous: [...previous, command.current], frame: []);
  }
}
