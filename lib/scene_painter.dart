import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kanji_workshop/scene.dart';
import 'package:kanji_workshop/vector.dart';

const strokeWidth = 6.0;
final black = Paint()
  ..style = PaintingStyle.stroke
  ..color = Colors.black
  ..strokeWidth = strokeWidth
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

final gray = Paint.from(black)..color = Color(0xa0d0d0d0);
final red = Paint.from(black)..color = Color(0xffff0000);
final blue = Paint.from(black)..color = Color.fromARGB(255, 110, 133, 237);
final ok = Paint.from(black)
  ..strokeWidth = 8.0
  ..color = Color.fromARGB(255, 110, 133, 237);

final hintPoint = Paint.from(black)
  ..color = Color(0xffff0000)
  ..strokeWidth = 10.0;

class Dash {
  final double width;
  final double space;
  final Paint paint;
  const Dash({required this.width, required this.space, required this.paint});
}

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

class ScenePainter extends CustomPainter {
  final double width;
  final double height;
  final Scene scene;

  const ScenePainter(this.scene, this.width, this.height);

  @override
  void paint(Canvas canvas, Size size) {
    final template = offsetsPath(scene.template);
    final previous = offsetsPath(scene.previous);
    final current = offsetsPath([
      scene.frame.isEmpty ? scene.current : scene.frame,
    ]);

    final dash = Dash(
      width: 6,
      space: 4,
      paint: Paint()
        ..color = Colors.red
        ..strokeWidth = 0.5,
    );

    drawDashedLine(
      canvas: canvas,
      start: Offset(width / 2, 0),
      end: Offset(width / 2, height),
      dash: dash,
    );

    drawDashedLine(
      canvas: canvas,
      start: Offset(0, height / 2),
      end: Offset(width, height / 2),
      dash: dash,
    );

    final complete = scene.template.length == scene.previous.length;

    if (scene.templateVisible) canvas.drawPath(template, gray);
    canvas.drawPath(previous, complete ? blue : black);
    canvas.drawPath(current, black);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
