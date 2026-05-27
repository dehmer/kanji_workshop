import 'dart:ui';
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
