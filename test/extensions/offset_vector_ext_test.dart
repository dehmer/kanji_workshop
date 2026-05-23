import 'package:test/test.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:kanji_workshop/extensions/offset_vector_ext.dart';

void main() {
  // group('[4dc8] OffsetVectorExt', () {});

  test('[cd7e] lengthSquared :: double', () {
    final c = [4.0, 6.0];
    final offset = Offset(c[0], c[1]);
    final expexted = c[0] * c[0] + c[1] * c[1];
    final actual = offset.lengthSquared;
    expect(actual, expexted);
  });

  test('[db8c] distanceTo :: Offset -> double', () {
    final c = [1.0, 1.0, 4.0, 5.0];
    final a = Offset(c[0], c[1]);
    final b = Offset(c[2], c[3]);
    final expected = (a - b).distance;
    final actual = a.distanceTo(b);
    expect(actual, expected);
  });

  test('[4efe] dot :: Offset -> double', () {
    final c = [2.0, 2.0, 3.0, 4.0];
    final a = Offset(c[0], c[1]);
    final b = Offset(c[2], c[3]);
    final expected = c[0] * c[2] + c[1] * c[3];
    final actual = a.dot(b);
    expect(actual, expected);
  });

  test('[4efe] signedAngleTo :: Offset -> double', () {
    final inputs = [
      (Offset(0.0, 1.0), Offset(0.0, 1.0), 0.0),
      (Offset(0.0, 1.0), Offset(1.0, 0.0), -math.pi / 2),
      (Offset(0.0, 1.0), Offset(0.0, -1.0), -math.pi),
      (Offset(0.0, 1.0), Offset(-1.0, 0.0), math.pi / 2),
    ];

    inputs.asMap().forEach((i, input) {
      final (a, b, expected) = input;
      final actual = a.signedAngleTo(b);
      expect(actual, expected);
    });
  });

  test('[4efe] normalized :: Offset -> Offset', () {
    final inputs = [
      (Offset(0.0, 4.0), Offset(0.0, 1.0)),
      (Offset(0.0, 0.0), Offset(0.0, 0.0)),
    ];

    inputs.asMap().forEach((i, input) {
      final (offset, expected) = input;
      final actual = offset.normalized();
      expect(actual, expected);
    });
  });
}
