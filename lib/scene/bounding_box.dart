import 'dart:ui' show Offset;

typedef BoundingBox = ({double minX, double minY, double maxX, double maxY});
typedef Extent = ({double width, double height});

final empty = (
  minX: double.infinity,
  minY: double.infinity,
  maxX: double.negativeInfinity,
  maxY: double.negativeInfinity,
);

BoundingBox union(BoundingBox box, dynamic xs) => switch (xs) {
  Offset(dx: var x, dy: var y) => (
    minX: x < box.minX ? x : box.minX,
    minY: y < box.minY ? y : box.minY,
    maxX: x > box.maxX ? x : box.maxX,
    maxY: y > box.maxY ? y : box.maxY,
  ),
  List<Offset>() => xs.fold(box, ((acc, x) => union(acc, x))),
  List<List<Offset>>() => xs.fold(box, ((acc, x) => union(acc, x))),
  _ => empty,
};

BoundingBox of(dynamic xs) => switch (xs) {
  List<Offset>() => xs.fold(empty, ((acc, x) => union(acc, x))),
  List<List<Offset>>() => xs.fold(empty, ((acc, x) => union(acc, x))),
  _ => empty,
};

Extent extent(BoundingBox box) =>
    (width: box.maxX - box.minX, height: box.maxY - box.minY);
