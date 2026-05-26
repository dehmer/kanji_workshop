import 'package:flutter/material.dart';

typedef Polyline = List<Offset>;
typedef PolylineList = List<List<Offset>>;

Polyline Function(Polyline) scalePolyline(double s) {
  return (line) => line.map((offset) => offset * s).toList();
}

PolylineList scalePolylineList(double s, PolylineList list) {
  return list.map(scalePolyline(s)).toList();
}
