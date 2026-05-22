/*
Implement algorithm in dart programming language morphing one 2d polyline into another 2d polyline.
Both polyline may have a different number of points.
Resampling may be required. 2D points should be represented by dart:ui Offset with possible extensions.
*/

import 'dart:math' as math;
import 'dart:ui';

/// ---------------------------------------------------------------------------
/// Offset extensions
/// ---------------------------------------------------------------------------

extension OffsetMath on Offset {
  double distanceTo(Offset other) => (this - other).distance;

  Offset lerpTo(Offset other, double t) {
    return Offset(dx + (other.dx - dx) * t, dy + (other.dy - dy) * t);
  }
}

/// ---------------------------------------------------------------------------
/// Polyline morphing
/// ---------------------------------------------------------------------------
///
/// Features:
/// - Works with different point counts
/// - Arc-length resampling
/// - Stable interpolation
/// - Supports open and closed polylines
///
/// Typical usage:
///
/// final morph = PolylineMorpher(
///   source,
///   target,
///   samples: 128,
/// );
///
/// final polylineAtHalf = morph.transform(0.5);
///
class PolylineMorpher {
  final List<Offset> _a;
  final List<Offset> _b;

  /// Both polylines are internally resampled to this count.
  final int samples;

  /// Whether polylines are closed loops.
  final bool closed;

  PolylineMorpher(
    List<Offset> polylineA,
    List<Offset> polylineB, {
    this.samples = 128,
    this.closed = false,
  }) : assert(samples >= 2),
       _a = _resample(polylineA, samples, closed: closed),
       _b = _resample(polylineB, samples, closed: closed);

  /// Returns interpolated polyline.
  ///
  /// t = 0.0 -> source
  /// t = 1.0 -> target
  List<Offset> transform(double t) {
    t = t.clamp(0.0, 1.0);

    return List.generate(samples, (i) {
      return _a[i].lerpTo(_b[i], t);
    });
  }

  /// -------------------------------------------------------------------------
  /// Resampling
  /// -------------------------------------------------------------------------

  static List<Offset> _resample(
    List<Offset> points,
    int count, {
    required bool closed,
  }) {
    if (points.length < 2) {
      throw ArgumentError('Polyline must contain at least 2 points.');
    }

    final pts = List<Offset>.from(points);

    if (closed && pts.first != pts.last) {
      pts.add(pts.first);
    }

    // Compute cumulative lengths.
    final cumulative = <double>[0.0];

    for (int i = 1; i < pts.length; i++) {
      cumulative.add(cumulative.last + pts[i - 1].distanceTo(pts[i]));
    }

    final totalLength = cumulative.last;

    if (totalLength <= 1e-9) {
      return List.filled(count, pts.first);
    }

    final result = <Offset>[];

    final maxIndex = closed ? count : count - 1;

    for (int i = 0; i < count; i++) {
      final u = i / maxIndex;
      final targetDistance = u * totalLength;

      result.add(_sampleAtDistance(pts, cumulative, targetDistance));
    }

    return result;
  }

  static Offset _sampleAtDistance(
    List<Offset> pts,
    List<double> cumulative,
    double distance,
  ) {
    int seg = 0;

    while (seg < cumulative.length - 2 && cumulative[seg + 1] < distance) {
      seg++;
    }

    final d0 = cumulative[seg];
    final d1 = cumulative[seg + 1];

    final p0 = pts[seg];
    final p1 = pts[seg + 1];

    final segmentLength = d1 - d0;

    if (segmentLength <= 1e-9) {
      return p0;
    }

    final t = (distance - d0) / segmentLength;

    return p0.lerpTo(p1, t);
  }
}

/// ---------------------------------------------------------------------------
/// Optional alignment utilities
/// ---------------------------------------------------------------------------
///
/// These significantly improve morph quality when:
/// - shapes are translated differently
/// - shapes have different scale
/// - shapes are rotated differently
///
class PolylineAlignment {
  static List<Offset> center(List<Offset> points) {
    final centroid = _centroid(points);

    return points.map((p) => p - centroid).toList();
  }

  static List<Offset> scaleToUnit(List<Offset> points) {
    double maxDistance = 0.0;

    for (final p in points) {
      maxDistance = math.max(maxDistance, p.distance);
    }

    if (maxDistance <= 1e-9) {
      return List.from(points);
    }

    return points
        .map((p) => Offset(p.dx / maxDistance, p.dy / maxDistance))
        .toList();
  }

  static Offset _centroid(List<Offset> points) {
    double x = 0.0;
    double y = 0.0;

    for (final p in points) {
      x += p.dx;
      y += p.dy;
    }

    return Offset(x / points.length, y / points.length);
  }
}

/*
/// ---------------------------------------------------------------------------
/// Example
/// ---------------------------------------------------------------------------

void main() {
  final source = <Offset>[
    Offset(0, 0),
    Offset(100, 0),
    Offset(150, 50),
    Offset(200, 0),
  ];

  final target = <Offset>[
    Offset(0, 100),
    Offset(50, 200),
    Offset(200, 50),
  ];

  final morpher = PolylineMorpher(
    source,
    target,
    samples: 64,
  );

  // Halfway morph.
  final halfway = morpher.transform(0.5);

  for (final p in halfway.take(10)) {
    print(p);
  }
}

*/
