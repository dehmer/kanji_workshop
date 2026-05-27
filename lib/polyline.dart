import 'package:flutter/material.dart';
import 'package:kanji_workshop/extensions/offset_vector_ext.dart';

typedef Polyline = List<Offset>;
typedef PolylineList = List<List<Offset>>;

Polyline Function(Polyline) scalePolyline(double s) {
  return (line) => line.map((offset) => offset * s).toList();
}

PolylineList scalePolylineList(double s, PolylineList list) {
  return list.map(scalePolyline(s)).toList();
}

Polyline tangents(Polyline points) {
  final tangents = <Offset>[];

  for (int i = 0; i < points.length; i++) {
    Offset dir;

    if (i == 0) {
      dir = points[1] - points[0];
    } else if (i == points.length - 1) {
      dir = points[i] - points[i - 1];
    } else {
      dir = points[i + 1] - points[i - 1];
    }

    tangents.add(dir.normalized());
  }

  return tangents;
}

double polylineLength(Polyline points) {
  double sum = 0.0;

  for (int i = 1; i < points.length; i++) {
    sum += (points[i] - points[i - 1]).distance;
  }

  return sum;
}

/// Resamples a polyline into equally spaced points.
///
/// This is important because DTW behaves much better when both
/// lines have approximately uniform sampling density.
List<Offset> resample(List<Offset> points, int samples) {
  if (points.length < 2) {
    return List.of(points);
  }

  final totalLength = polylineLength(points);

  if (totalLength == 0) {
    return List.filled(samples, points.first);
  }

  final step = totalLength / (samples - 1);

  final result = <Offset>[points.first];

  double accumulated = 0.0;
  int segmentIndex = 0;

  Offset current = points.first;

  while (result.length < samples - 1) {
    final next = points[segmentIndex + 1];
    final segment = next - current;
    final segmentLength = segment.distance;

    if (accumulated + segmentLength >= step) {
      final remain = step - accumulated;
      final t = remain / segmentLength;

      final newPoint = Offset(
        current.dx + segment.dx * t,
        current.dy + segment.dy * t,
      );

      result.add(newPoint);

      current = newPoint;
      accumulated = 0.0;
    } else {
      accumulated += segmentLength;
      segmentIndex++;

      if (segmentIndex >= points.length - 1) {
        break;
      }

      current = points[segmentIndex];
    }
  }

  result.add(points.last);
  return result;
}
