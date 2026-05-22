import 'package:flutter/material.dart';

class PathPainter extends CustomPainter {
  final Path _path;
  final Paint _paint;

  PathPainter(this._path, this._paint);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(_path, _paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
