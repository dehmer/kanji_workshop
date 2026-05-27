import 'package:flutter/foundation.dart' show immutable;
import 'package:kanji_workshop/polyline.dart';
import 'package:kanji_workshop/scene/command.dart';
import 'package:kanji_workshop/scene/behavior.dart';

@immutable
class Scene {
  final Behavior behavior;
  final bool templateVisible;
  final PolylineList template;
  final PolylineList previous;
  final Polyline current;
  final Polyline frame;

  const Scene({
    required this.behavior,
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
    behavior: this.behavior,
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
    final complete = this.previous.length == this.template;
    return complete ? behavior.onLastStroke(this) : behavior.onStroke(this);
  }

  Scene animationEnd(AnimationEnd command) {
    return copyWith(previous: [...previous, command.current], frame: []);
  }
}
