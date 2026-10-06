import 'dart:collection';

/// An in-memory working set. Eviction never deletes persistent documents.
class BoundedLruCache<K, V> extends MapBase<K, V> {
  BoundedLruCache({required this.capacity}) : assert(capacity > 0);
  final int capacity;
  final LinkedHashMap<K, V> _entries = LinkedHashMap<K, V>();

  @override
  V? operator [](Object? key) {
    if (!_entries.containsKey(key)) return null;
    final value = _entries.remove(key) as V;
    _entries[key as K] = value;
    return value;
  }

  @override
  void operator []=(K key, V value) {
    _entries.remove(key);
    _entries[key] = value;
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  @override
  Iterable<K> get keys => _entries.keys.toList(growable: false);
  @override
  void clear() => _entries.clear();
  @override
  V? remove(Object? key) => _entries.remove(key);
  @override
  bool containsKey(Object? key) => _entries.containsKey(key);
}
