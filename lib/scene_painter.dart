import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'scene/scene.dart';
import 'polyline.dart';

const strokeWidth = 4.0;
final black = Paint()
  ..style = PaintingStyle.stroke
  ..color = Colors.black
  ..strokeWidth = strokeWidth
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

final gray = Paint.from(black)
  ..color = Color(0xffd0d0d0)
  ..strokeWidth = strokeWidth;

final red = Paint.from(black)..color = Color(0xffff0000);
final blue = Paint.from(black)..color = Color.fromARGB(255, 110, 133, 237);
final ok = Paint.from(black)..color = Color.fromARGB(255, 110, 133, 237);

final hintPoint = Paint.from(black)
  ..color = Color(0xffff0000)
  ..strokeWidth = 10.0;

class Dash {
  final double width;
  final double space;
  final Paint paint;
  const Dash({required this.width, required this.space, required this.paint});
}

final gridDash = Dash(
  width: 6,
  space: 4,
  paint: Paint()
    ..color = Colors.red
    ..strokeWidth = 0.5,
);

void drawDashedLine({
  required Canvas canvas,
  required Offset start,
  required Offset end,
  required Dash dash,
}) {
  // Get normalized distance vector from p1 to p2
  var dx = end.dx - start.dx;
  var dy = end.dy - start.dy;
  final magnitude = math.sqrt(dx * dx + dy * dy);
  dx = dx / magnitude;
  dy = dy / magnitude;

  // Compute number of dash segments
  final steps = magnitude ~/ (dash.width + dash.space);

  var startX = start.dx;
  var startY = start.dy;

  for (int i = 0; i < steps; i++) {
    final endX = startX + dx * dash.width;
    final endY = startY + dy * dash.width;
    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), dash.paint);
    startX += dx * (dash.width + dash.space);
    startY += dy * (dash.width + dash.space);
  }
}

Path offsetsPath(PolylineList pointList) {
  final path = Path();
  for (int i = 0; i < pointList.length; i++) {
    path.addPolygon(pointList[i], false);
  }

  return path;
}

Path Function(PolylineList) createScaledPath(double s) {
  final m = Matrix4.identity()..scaleByDouble(s, s, 0, 0);

  return (list) {
    final path = Path();
    final scaled = transform(m, list);
    for (int i = 0; i < scaled.length; i++) {
      path.addPolygon(scaled[i], false);
    }

    return path;
  };
}

class ScenePainter extends CustomPainter {
  final Scene scene;
  final double dimension;

  const ScenePainter(this.scene, this.dimension);

  @override
  void paint(Canvas canvas, Size size) {
    final createPath = createScaledPath(dimension);
    final template = createPath(scene.target);
    final actual = createPath(scene.actual);

    createPath(scene.actual);
    final current = createPath([scene.current]);
    final frame = createPath(scene.frame);

    if (scene.gridVisible) {
      drawDashedLine(
        canvas: canvas,
        start: Offset(dimension / 2, 0),
        end: Offset(dimension / 2, dimension),
        dash: gridDash,
      );

      drawDashedLine(
        canvas: canvas,
        start: Offset(0, dimension / 2),
        end: Offset(dimension, dimension / 2),
        dash: gridDash,
      );
    }

    if (scene.targetVisible) {
      canvas.drawPath(template, gray);
    }

    // Depending on animation frame, draw previous and/or current.
    final complete =
        scene.actual.isNotEmpty &&
        scene.actual.length == scene.target.length &&
        scene.frame.isEmpty;

    if (scene.frame.isEmpty) canvas.drawPath(current, black);
    final drawPrevious = scene.frame.isEmpty || scene.frame.length == 1;
    final drawCurrent = scene.frame.isEmpty;

    if (drawPrevious) canvas.drawPath(actual, complete ? ok : black);
    if (drawCurrent) canvas.drawPath(current, black);
    canvas.drawPath(frame, black);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
