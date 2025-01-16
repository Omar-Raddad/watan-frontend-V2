class PriorityQueue<T> {
  final List<T> _elements = [];
  final int Function(T a, T b) _comparator;

  PriorityQueue(this._comparator);

  void add(T element) {
    _elements.add(element);
    _elements.sort(_comparator);
  }

  T removeFirst() {
    return _elements.removeAt(0);
  }

  bool contains(T element) {
    return _elements.contains(element);
  }

  bool get isEmpty => _elements.isEmpty;

  bool get isNotEmpty => _elements.isNotEmpty; // Added getter
}
