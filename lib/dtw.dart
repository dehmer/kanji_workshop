/* ChatGPT prompt:
Please implement a direction-aware algorithm in dart wich compares two 2d
line strings (polylines) based on dynamic time warp algorithm (DTW).
2D point should be represented by dart:ui Offset class, possibly with an
extension to Offset. Resampling of inputs is allowed.
*/

import 'dart:math' as math;
import 'dart:ui';
import 'extensions/offset_vector_ext.dart';

double polylineLength(List<Offset> points) {
  double sum = 0.0;

  for (int i = 1; i < points.length; i++) {
    sum += (points[i] - points[i - 1]).distance;
  }

  return sum;
}

List<Offset> tangents(List<Offset> points) {
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

/// ============================================================
/// Polyline DTW comparer
/// ============================================================

class PolylineDTW {
  /// Direction-aware DTW distance between two polylines.
  ///
  /// Lower score means more similar.
  ///
  /// The algorithm combines:
  /// - positional distance
  /// - tangent direction similarity
  ///
  /// `directionWeight`:
  ///   0.0 => only geometry
  ///   1.0 => geometry + direction strongly enforced
  static double compare(
    List<Offset> a,
    List<Offset> b, {
    int resampleCount = 64, // TODO: no implicit resampling
    double directionWeight = 0.5,
    bool normalize = true,
  }) {
    if (a.length < 2 || b.length < 2) {
      throw ArgumentError('Both polylines must contain at least 2 points.');
    }

    final resamplingNeeded = a.length != b.length;
    final aa = resamplingNeeded ? resample(a, resampleCount) : a;
    final bb = resamplingNeeded ? resample(b, resampleCount) : b;

    final ta = tangents(aa);
    final tb = tangents(bb);

    final n = aa.length;
    final m = bb.length;

    final dtw = List.generate(
      n + 1,
      (_) => List<double>.filled(m + 1, double.infinity),
    );

    dtw[0][0] = 0.0;

    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        final posDist = aa[i - 1].distanceTo(bb[j - 1]);

        // Direction penalty:
        // 0 => same direction
        // 2 => opposite direction
        final dirPenalty = 1.0 - ta[i - 1].dot(tb[j - 1]).clamp(-1.0, 1.0);

        final cost = posDist * (1.0 + dirPenalty * directionWeight);

        final bestPrevious = math.min(
          dtw[i - 1][j],
          math.min(dtw[i][j - 1], dtw[i - 1][j - 1]),
        );

        dtw[i][j] = cost + bestPrevious;
      }
    }

    final score = dtw[n][m];

    if (!normalize) {
      return score;
    }

    return score / (n + m);
  }
}

/* Usage:

void main() {
  final lineA = [
    const Offset(0, 0),
    const Offset(50, 0),
    const Offset(100, 50),
  ];

  final lineB = [
    const Offset(0, 0),
    const Offset(40, 5),
    const Offset(90, 55),
  ];

  final lineC = [
    const Offset(100, 50),
    const Offset(50, 0),
    const Offset(0, 0),
  ];

  final ab = PolylineDTW.compare(
    lineA,
    lineB,
    directionWeight: 0.7,
  );

  final ac = PolylineDTW.compare(
    lineA,
    lineC,
    directionWeight: 0.7,
  );

  print('A vs B: $ab');
  print('A vs reversed C: $ac');
}

*/
