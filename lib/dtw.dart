/* ChatGPT prompt:
Please implement a direction-aware algorithm in dart wich compares two 2d
line strings (polylines) based on dynamic time warp algorithm (DTW).
2D point should be represented by dart:ui Offset class, possibly with an
extension to Offset. Resampling of inputs is allowed.
*/

import 'dart:math' as math;
import 'dart:ui';
import 'extensions/offset_vector_ext.dart';
import 'polyline.dart';

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
    int resampleCount = 32,
    double directionWeight = 1,
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
    return score / (n + m);
  }
}
