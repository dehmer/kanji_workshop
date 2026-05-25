import 'dart:math' as math;
import 'dart:ui';

/// ============================================================
/// Offset extensions
/// ============================================================

extension OffsetVectorExt on Offset {
  double get lengthSquared => dx * dx + dy * dy;

  double distanceTo(Offset other) => (this - other).distance;

  double dot(Offset other) => dx * other.dx + dy * other.dy;

  /// Signed angle between vectors in radians.
  double signedAngleTo(Offset other) {
    final cross = dx * other.dy - dy * other.dx;
    final dotValue = dot(other);
    return math.atan2(cross, dotValue);
  }

  Offset normalized() {
    final len = distance;
    if (len == 0) return Offset.zero;
    return this / len;
  }
}
