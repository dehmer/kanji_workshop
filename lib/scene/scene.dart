import 'package:flutter/foundation.dart' show immutable;
import '../polyline.dart';
import '../scene/command.dart';
import '../scene/behavior.dart';

@immutable
class Scene {
  final Behavior behavior;
  final bool templateVisible;
  final bool gridVisible;
  final PolylineList template;
  final PolylineList previous;
  final Polyline current;

  /// Animation frame for one or multiple strokes.
  final PolylineList frame;
  final int misses;

  const Scene({
    required this.behavior,
    bool? templateVisible,
    bool? gridVisible,
    PolylineList? template,
    PolylineList? previous,
    Polyline? current,
    PolylineList? frame,
    int? misses,
  }) : templateVisible = templateVisible ?? true,
       gridVisible = gridVisible ?? true,
       template = template ?? const [],
       previous = previous ?? const [],
       current = current ?? const [],
       frame = frame ?? const [],
       misses = misses ?? 0;

  Scene copyWith({
    bool? templateVisible,
    bool? gridVisible,
    PolylineList? template,
    PolylineList? previous,
    Polyline? current,
    PolylineList? frame,
    int? misses,
  }) => Scene(
    behavior: behavior,
    templateVisible: templateVisible ?? this.templateVisible,
    gridVisible: gridVisible ?? this.gridVisible,
    template: template ?? this.template,
    previous: previous ?? this.previous,
    current: current ?? this.current,
    frame: frame ?? this.frame,
    misses: misses ?? this.misses,
  );

  Scene reduce(SceneCommand command) => switch (command) {
    Initialize() => initialize(command),
    DragStart() => dragStart(command),
    DragUpdate() => dragUpdate(command),
    DragEnd() => dragEnd(command),
    Reset() => copyWith(previous: [], current: [], misses: 0),
    AnimationFrame(frame: final f) => copyWith(frame: f),
    AnimationEnd() => animationEnd(command),
    ToggleTemplate() => copyWith(templateVisible: !templateVisible),
    ToggleGrid() => copyWith(gridVisible: !gridVisible),
    NullCommand() => this,
  };

  Scene dragStart(DragStart command) {
    if (previous.length == template.length) return this;
    return behavior.dragStart(command, this);
  }

  Scene dragUpdate(DragUpdate command) {
    if (previous.length == template.length) return this;
    return copyWith(current: [...current, command.position]);
  }

  Scene dragEnd(DragEnd command) {
    if (previous.length == template.length) return this;
    return behavior.dragEnd(command, this);
  }

  Scene initialize(Initialize command) {
    return copyWith(
      template: command.template,
      previous: [],
      current: [],
      frame: [],
    );
  }

  Scene animationEnd(AnimationEnd command) {
    return copyWith(frame: []);
  }
}
