import 'package:flutter/material.dart';
import 'package:kanji_workshop/scene.dart';
import 'package:kanji_workshop/vector.dart';

const strokeWidth = 5.0;
final black = Paint()
  ..style = PaintingStyle.stroke
  ..color = Colors.black
  ..strokeWidth = strokeWidth
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

final gray = Paint.from(black)..color = Color(0xffd0d0d0);
final red = Paint.from(black)..color = Color(0xffff0000);
final blue = Paint.from(black)..color = Color.fromARGB(255, 110, 133, 237);

class ScenePainter extends CustomPainter {
  final Scene scene;

  const ScenePainter(this.scene);

  @override
  void paint(Canvas canvas, Size size) {
    final template = offsetsPath(scene.template);
    final previous = offsetsPath(scene.previous);
    final current = offsetsPath([
      scene.frame.isEmpty ? scene.current : scene.frame,
    ]);

    canvas.drawPath(template, gray);
    canvas.drawPath(previous, black);
    canvas.drawPath(current, black);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
