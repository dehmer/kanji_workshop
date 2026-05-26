import 'dart:ui' show Offset;
import 'package:kanji_workshop/polyline.dart' show Polyline;

/// Uniform SVG height and width.
const dimension = 109.0;

final delimiter = RegExp(r'[ ML]');

/// splitPath :: String -> [double]
/// Split simple SVG path data only containing M and L instructions.
Iterable<double> splitPath(String s) {
  final [_, ...tokens] = s.split(delimiter);
  return tokens.map((token) => double.parse(token));
}

/// splitEvery :: int -> [T] -> [[T]]
/// Split a list into slices of the specified length.
List<List<T>> splitEvery<T>(int n, List<T> list) {
  List<List<T>> acc = [];

  for (var i = 0; i < list.length; i += n) {
    acc.add(list.sublist(i, i + n));
  }

  return acc;
}

/// parseRow :: (double -> double) -> {k: v} -> [Offset]
/// Parse a single row from database query containing SVG 'path' column.
Polyline Function(Map<String, Object?>) parseRow(double transform(double)) {
  return (row) {
    Offset offset(tuple) => Offset(tuple[0], tuple[1]);
    final path = splitPath(row['path']!.toString()).map(transform).toList();
    return splitEvery(2, path).map(offset).toList();
  };
}
