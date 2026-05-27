import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:kanji_workshop/dtw.dart';
import 'package:kanji_workshop/polyline.dart';

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

class ShowTemplate extends SceneCommand {
  final bool visible;
  ShowTemplate(this.visible);
}

@immutable
class Scene {
  final void Function(Polyline, Polyline) onMatch;
  final bool templateVisible;
  final PolylineList template;
  final PolylineList previous;
  final Polyline current;
  final Polyline frame;

  const Scene({
    required this.onMatch,
    bool? templateVisible,
    PolylineList? template,
    PolylineList? previous,
    Polyline? current,
    Polyline? frame,
    int? misses,
  }) : templateVisible = templateVisible ?? true,
       template = template ?? const [],
       previous = previous ?? const [],
       current = current ?? const [],
       frame = frame ?? const [];

  Scene copyWith({
    bool? templateVisible,
    PolylineList? template,
    PolylineList? previous,
    Polyline? current,
    Polyline? frame,
  }) => Scene(
    onMatch: this.onMatch,
    templateVisible: templateVisible ?? this.templateVisible,
    template: template ?? this.template,
    previous: previous ?? this.previous,
    current: current ?? this.current,
    frame: frame ?? this.frame,
  );

  Scene reduce(SceneCommand command) => switch (command) {
    Initialize() => initialize(command),
    DragStart() => dragStart(command),
    DragUpdate() => dragUpdate(command),
    DragEnd() => dragEnd(command),
    Reset() => copyWith(previous: [], current: []),
    AnimationFrame(frame: final f) => copyWith(frame: f),
    AnimationEnd() => animationEnd(command),
    ShowTemplate(visible: final v) => copyWith(templateVisible: v),
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

  Scene dragStart(DragStart command) {
    return copyWith(current: [...current, command.position]);
  }

  Scene dragUpdate(DragUpdate command) {
    return copyWith(current: [...current, command.position]);
  }

  Scene dragEnd(DragEnd _) {
    final index = previous.length;
    final template = this.template[index];
    final current = resample(this.current, template.length);

    final distance = PolylineDTW.compare(template, current);
    if (distance < 0.06) {
      onMatch(current, template); // Trigger animation of current stroke.
      return copyWith(current: []);
    } else {
      // Reset; start over.
      return copyWith(previous: [], current: []);
    }
  }

  Scene animationEnd(AnimationEnd command) {
    return copyWith(previous: [...previous, command.current], frame: []);
  }
}
