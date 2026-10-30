/// A sorted copy that keeps equal items in their input order. Dart's
/// `List.sort` is not stable, and JavaScript's, which the web relies on, is.
List<T> stableSorted<T>(Iterable<T> items, int Function(T a, T b) compare) {
  final indexed = [for (final (i, item) in items.indexed) (i, item)];
  indexed.sort((a, b) {
    final order = compare(a.$2, b.$2);
    return order != 0 ? order : a.$1.compareTo(b.$1);
  });
  return [for (final (_, item) in indexed) item];
}
