import 'package:flutter/material.dart';

typedef Stroke = String;
typedef StrokeList = List<String>;
typedef Polyline = List<Offset>;
typedef PolylineList = List<List<Offset>>;

const vgDimension = 110;
RegExp pathDelimiter = RegExp(r'[ ML]');

List<double> splitPath(String s) {
  final [_, ...tokens] = s.split(pathDelimiter);
  return tokens.map((token) => double.parse(token)).toList();
}

/// aperture :: Number → [a] → [[a]]
/// Returns a new list, composed of n-tuples of consecutive elements.
/// If n is greater than the length of the list, an empty list is returned.
List<List<T>> aperture<T>(int n, List<T> list) {
  int idx = 0;
  int limit = list.length - (n - 1);
  List<List<T>> acc = [];

  while (idx < limit) {
    acc.add(list.sublist(idx, idx + n));
    idx += 1;
  }

  return acc;
}

/// splitEvery :: Number → [a] → [[a]]
/// Splits a list into slices of the specified length.
List<List<T>> splitEvery<T>(int n, List<T> list) {
  int idx = 0;
  List<List<T>> acc = [];

  while (idx < list.length) {
    acc.add(list.sublist(idx, idx += n));
  }

  return acc;
}

List<List<Offset>> scaleSVG(double scale, List<List<List<double>>> lines) {
  return lines.map((line) {
    return line.map((coords) {
      return Offset(coords[0] * scale, coords[1] * scale);
    }).toList();
  }).toList();
}

Path offsetsPath(PolylineList pointList) {
  final path = Path();
  for (int i = 0; i < pointList.length; i++) {
    path.addPolygon(pointList[i], false);
  }

  return path;
}

List<List<Offset>> svgToPolyline(List<String> svg, double factor) {
  Offset offset(tuple) => Offset(tuple[0], tuple[1]);
  double scale(n) => n * factor;

  return svg
      .map((s) => splitPath(s).map(scale).toList())
      .map((xs) => splitEvery(2, xs).map(offset).toList())
      .toList();
}

Path strokesPath(List<String> strokes, double factor) {
  Offset offset(tuple) => Offset(tuple[0], tuple[1]);
  double scale(n) => n * factor;

  final pointList = strokes
      .map((s) => splitPath(s).map(scale).toList())
      .map((xs) => splitEvery(2, xs).map(offset).toList())
      .toList();
  return offsetsPath(pointList);
}
