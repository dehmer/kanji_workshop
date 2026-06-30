import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import '../polyline.dart';
import '../dtw.dart';
import '../scene/animate.dart';
import '../request_sender.dart';

final sender = LineStringSender();

sealed class SceneCommand {}

class NullCommand extends SceneCommand {}

class Reset extends SceneCommand {}

class Event extends SceneCommand {
  final PointerEvent event;
  Event(this.event);
}

class AnimationFrame extends SceneCommand {
  final PolylineList frame;
  AnimationFrame(this.frame);
}

class AnimationEnd extends SceneCommand {
  final Polyline current;
  AnimationEnd(this.current);
}

class ToggleTarget extends SceneCommand {
  ToggleTarget();
}

class ToggleGrid extends SceneCommand {
  ToggleGrid();
}

class Scene {
  final FlutterSignal<SceneCommand> feed;
  final String literal;
  final Offset Function(Offset) scalePosition;
  final List<PointerEvent> events;
  final bool targetVisible;
  final bool gridVisible;
  final PolylineList target;
  final PolylineList actual;
  final Polyline current;

  /// Animation frame for one or multiple strokes.
  final PolylineList frame;

  Scene({
    required this.feed,
    required this.literal,
    required this.scalePosition,
    List<PointerEvent>? events,
    bool? targetVisible,
    bool? gridVisible,
    PolylineList? target,
    PolylineList? actual,
    Polyline? current,
    PolylineList? frame,
  }) : events = events ?? const [],
       targetVisible = targetVisible ?? true,
       gridVisible = gridVisible ?? true,
       target = target ?? const [],
       actual = actual ?? const [],
       current = current ?? const [],
       frame = frame ?? const [];

  Scene copyWith({
    List<PointerEvent>? events,
    bool? targetVisible,
    bool? gridVisible,
    PolylineList? target,
    PolylineList? actual,
    Polyline? current,
    PolylineList? frame,
  }) => Scene(
    feed: feed,
    literal: literal,
    scalePosition: scalePosition,
    events: events ?? this.events,
    targetVisible: targetVisible ?? this.targetVisible,
    gridVisible: gridVisible ?? this.gridVisible,
    target: target ?? this.target,
    actual: actual ?? this.actual,
    current: current ?? this.current,
    frame: frame ?? this.frame,
  );

  Scene reduce(SceneCommand command) => switch (command) {
    Event() => event(command),
    Reset() => copyWith(actual: [], current: [], events: []),
    AnimationFrame(frame: final f) => copyWith(frame: f),
    AnimationEnd() => animationEnd(command),
    ToggleTarget() => copyWith(targetVisible: !targetVisible),
    ToggleGrid() => copyWith(gridVisible: !gridVisible),
    NullCommand() => this,
  };

  void animateStroke(Polyline current, Polyline target) {
    void callback(t) {
      Offset lerp(i) => Offset.lerp(current[i], target[i], t)!;
      final frame = List.generate(target.length, lerp);
      feed.value = AnimationFrame([frame]);
    }

    void end() => feed.value = AnimationEnd(target);
    animate(callback: callback, end: end);
  }

  Scene match(List<PointerEvent> events, Polyline current, Polyline target) {
    // Don't add current stroke to actual strokes.
    // Coresponding stroke from target is added at the end of animation.

    // without animation:
    // final actual = [...this.actual, current];
    // if (actual.isNotEmpty && actual.length == this.target.length) {
    //   sender.sendEvents(literal, scalePosition, events);
    // }
    // return copyWith(events: events, actual: actual, current: []);

    // with animation:
    animateStroke(current, target);
    return copyWith(events: events, current: []);
  }

  Scene mismatch(List<PointerEvent> events, Polyline current, Polyline target) {
    // Remove events for last stroke (current).
    events.removeLast();
    while (events.isNotEmpty && events.last.down) {
      events.removeLast();
    }

    return copyWith(current: [], events: events);
  }

  Scene pointerDown(List<PointerEvent> events) {
    final event = events.last;
    final current = [...this.current, scalePosition(event.localPosition)];
    return copyWith(events: events, current: current);
  }

  Scene pointerMove(List<PointerEvent> events) {
    final event = events.last;
    final current = [...this.current, scalePosition(event.localPosition)];
    return copyWith(events: events, current: current);
  }

  Scene pointerUp(List<PointerEvent> events) {
    final event = events.last;

    final target = this.target[actual.length];
    Polyline current = [...this.current, scalePosition(event.localPosition)];
    current = resample(this.current, target.length);

    if (current.length < 2) {
      return mismatch(events, current, target);
    }

    final distance = PolylineDTW.compare(target, current);
    return switch (distance) {
      < 0.04 => match(events, current, target),
      _ => mismatch(events, current, target),
    };
  }

  Scene event(Event command) {
    if (actual.length == target.length) return this;
    final PointerEvent event = command.event;

    // Unconditionally add event to event list.
    final events = [...this.events, event];

    return switch (event) {
      PointerDownEvent() => pointerDown(events),
      PointerMoveEvent() => pointerMove(events),
      PointerUpEvent() => pointerUp(events),
      _ => this,
    };

    // if (event is PointerDownEvent) {
    //   // Ignore pointer down in general.
    //   return this;
    // } else if (event is PointerMoveEvent) {
    //   // Ignore move for distance squared = 0 and a pressure too low.
    //   if (event.delta.distanceSquared == 0 || event.pressure < 0.4) {
    //     return this;
    //   } else {
    //     return eventDown([...events, fromEvent(event)]);
    //   }
    // } else {
    //   // No need to handle up:
    //   if (events.isEmpty) return this;

    //   // Don't add up-event, but set previous/last event to pen up.
    //   events.last = (
    //     position: events.last.position,
    //     delta: events.last.delta,
    //     timeStamp: events.last.timeStamp,
    //     pressure: events.last.pressure,
    //     down: false,
    //   );

    //   return eventUp(events);
    // }
  }

  Scene animationEnd(AnimationEnd command) {
    final actual = [...this.actual, command.current];
    return copyWith(actual: actual, frame: []);
  }
}
