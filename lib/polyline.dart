import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector4;
import 'package:flutter/material.dart' show Offset;
import 'package:kanji_workshop/extensions/offset_vector_ext.dart';

typedef Polyline = List<Offset>;
typedef PolylineList = List<List<Offset>>;

Vector4 toVector4(Offset v) => Vector4(v.dx, v.dy, 0.0, 1.0);
Offset toOffset(Vector4 v) => Offset(v[0], v[1]);

/// transform :: (Matrix4, Offset) -> Offset
/// transform :: (Matrix4, List<Offset>) -> List<Offset>
/// transform :: (Matrix4, List<List<Offset>>) -> List<List<Offset>>
T transform<T>(Matrix4 m, T v) {
  return switch (v) {
        Offset() => toOffset(m.transform(toVector4(v))),
        List<Offset>() => v.map((v) => transform(m, v)).toList(),
        List<List<Offset>>() => v.map((v) => transform(m, v)).toList(),
        _ => v,
      }
      as T;
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

double polylineLength(Polyline xs) {
  double sum = 0.0;

  for (int i = 1; i < xs.length; i++) {
    sum += (xs[i] - xs[i - 1]).distance;
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
