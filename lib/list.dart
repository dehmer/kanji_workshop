/// aperture :: Number → [a] → [[a]]
/// Returns a new list, composed of n-tuples of consecutive elements.
/// If n is greater than the length of the list, an empty list is returned.
List<List<T>> aperture<T>(int n, List<T> list) {
  int idx = 0;
  int limit = list.length - (n - 1);
  List<List<T>> acc = [];

  while (idx < limit) {
    acc.add(list.sublist(idx, idx + n));
    idx += 1;
  }

  return acc;
}
