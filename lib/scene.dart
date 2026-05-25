import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:kanji_workshop/dtw.dart';
import 'package:kanji_workshop/vector.dart';

sealed class SceneCommand {}

class NullCommand extends SceneCommand {}

class Initialize extends SceneCommand {
  final PolylineList template;
  Initialize(this.template);
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
  final PolylineList template;
  final PolylineList previous;
  final Polyline current;
  final Polyline frame;

  const Scene({
    required this.onMatch,
    PolylineList? template,
    PolylineList? previous,
    Polyline? current,
    Polyline? frame,
  }) : template = template ?? const [],
       previous = previous ?? const [],
       current = current ?? const [],
       frame = frame ?? const [];

  Scene copyWith({
    PolylineList? template,
    PolylineList? previous,
    Polyline? current,
    Polyline? frame,
  }) => Scene(
    onMatch: this.onMatch,
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
      template: command.template,
      previous: [],
      current: [],
      frame: [],
    );
  }

  Scene dragEnd(DragEnd _) {
    final index = previous.length;
    final template = this.template[index];
    final current = resample(this.current, template.length);
    final directionWeight = 0.5;
    final distance = PolylineDTW.compare(
      template,
      current,
      directionWeight: directionWeight,
    );

    if (distance < 10.0) {
      onMatch(current, template);
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
