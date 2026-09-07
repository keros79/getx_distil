import 'dart:async';
import 'dart:collection';
import 'dart:math' show Random;

import 'rx_core.dart';

/// Shared dirty-flag + microtask batching pipeline used by every reactive
/// collection ([RxList], [RxMap], [RxSet]).
///
/// ### Batching Guarantee
/// Any number of mutating calls made synchronously within the same Dart event
/// (e.g., inside a `for` loop) will only schedule **one** microtask. The
/// microtask fires after all synchronous work has finished, calling [refresh]
/// exactly once and resetting the dirty flag.
mixin RxBatchNotifier<T> on GetListenable<T> {
  /// Guards against redundant microtask scheduling. Acts as the "isDirty"
  /// state lock: `true` while a notification microtask is queued.
  bool _isNotificationScheduled = false;

  /// Core optimization gate.
  ///
  /// On the **first** mutating call within a synchronous frame:
  ///   1. [_isNotificationScheduled] is `false` → proceed.
  ///   2. Flip the flag to `true` so every subsequent call in the same frame
  ///      is a no-op (the redundant notification is **dropped**).
  ///   3. Schedule a microtask; inside it, call [refresh] once and reset the
  ///      flag, making the system ready for the next frame's mutations.
  void autoBatchRefresh() {
    if (_isNotificationScheduled) return; // ← drop-path: already queued
    _isNotificationScheduled = true;
    scheduleMicrotask(() {
      _isNotificationScheduled = false;
      refresh(); // Obx widget updaters
      notifyStream(); // ever / once / debounce stream workers
    });
  }

  /// Disposes all listeners and the stream controller.
  ///
  /// Also resets the dirty flag so that any microtask already queued before
  /// [close] was called becomes a safe no-op — it will still run but
  /// [refresh] and [notifyStream] will find empty listener lists.
  @override
  void close() {
    _isNotificationScheduled = false; // cancel zombie microtask flag
    super.close();
  }
}

/// A reactive list that coalesces high-frequency write operations into a single
/// UI notification per event-loop turn using a dirty-flag + microtask pipeline.
///
/// ### Batching Guarantee
/// Any number of mutating calls made synchronously within the same Dart event
/// (e.g., inside a `for` loop) will only schedule **one** microtask. The
/// microtask fires after all synchronous work has finished, calling [refresh]
/// exactly once and resetting the dirty flag.
///
/// ### Read Fast-Path
/// Element reads (`[]`, [length], [iterator]) check [Notifier.isTracking] and
/// only register the reactive dependency when an [Obx] widget is building.
/// Background loops or pipeline code that simply reads the list pay zero
/// overhead from the global proxy tracking system.
///
/// ### Stream / `ever` Worker Compatibility
/// [refresh] emits the current [List<E>] snapshot to the internal broadcast
/// stream, so [ever], [once], and [debounce] workers continue to work
/// transparently.
class RxList<E> extends GetListenable<List<E>>
    with ListMixin<E>, RxBatchNotifier<List<E>> {
  // ─── Construction ──────────────────────────────────────────────────────────

  /// Creates an [RxList] pre-populated with [initial] elements.
  RxList([List<E>? initial]) : super(List<E>.of(initial ?? <E>[]));

  // ─── Convenience shorthand ─────────────────────────────────────────────────

  /// The unguarded backing list via the @protected [internalValue] accessor.
  /// Use only for non-reactive internal mutations.
  List<E> get _list => internalValue;

  // ─── ListMixin contract ────────────────────────────────────────────────────
  //
  // [ListMixin] delegates ALL default List operations to the four primitives
  // below: `length` getter, `length` setter, `[]` operator, and `[]=`
  // operator. We intercept writes at []=, [length=], and at the high-level
  // mutators to route through [autoBatchRefresh].

  @override
  int get length {
    // Fast-path read defense: only register a reactive dependency when an
    // Obx widget is actively tracking.
    if (Notifier.isTracking) reportRead();
    return _list.length;
  }

  @override
  set length(int newLength) {
    if (_list.length == newLength) return; // no-op guard
    _list.length = newLength;
    autoBatchRefresh();
  }

  @override
  E operator [](int index) {
    if (Notifier.isTracking) reportRead();
    return _list[index];
  }

  @override
  void operator []=(int index, E value) {
    _list[index] = value;
    autoBatchRefresh();
  }

  // ─── High-Level Mutators ───────────────────────────────────────────────────

  @override
  void add(E element) {
    _list.add(element);
    autoBatchRefresh();
  }

  @override
  void addAll(Iterable<E> iterable) {
    _list.addAll(iterable);
    autoBatchRefresh();
  }

  @override
  bool remove(Object? element) {
    final removed = _list.remove(element);
    if (removed) autoBatchRefresh();
    return removed;
  }

  @override
  E removeAt(int index) {
    final element = _list.removeAt(index);
    autoBatchRefresh();
    return element;
  }

  @override
  void clear() {
    if (_list.isEmpty) return; // nothing changed → skip notification
    _list.clear();
    autoBatchRefresh();
  }

  /// Replaces all contents with [iterable] in a single atomic operation.
  ///
  /// Regardless of how many elements are swapped in, exactly **one**
  /// microtask is scheduled, guaranteeing one [Obx] rebuild.
  void assignAll(Iterable<E> iterable) {
    _list
      ..clear()
      ..addAll(iterable);
    autoBatchRefresh();
  }

  /// Sorts the list in-place and schedules exactly **one** notification,
  /// bypassing the per-swap `[]=` hot-path that [ListMixin] would otherwise use.
  @override
  void sort([int Function(E a, E b)? compare]) {
    _list.sort(compare);
    autoBatchRefresh();
  }

  /// Shuffles the list in-place and schedules exactly **one** notification,
  /// bypassing the per-swap `[]=` hot-path that [ListMixin] would otherwise use.
  @override
  void shuffle([Random? random]) {
    _list.shuffle(random);
    autoBatchRefresh();
  }

  // ─── Iterator ──────────────────────────────────────────────────────────────

  @override
  Iterator<E> get iterator {
    if (Notifier.isTracking) reportRead();
    return _list.iterator;
  }

  // ─── GetListenable value override ─────────────────────────────────────────
  //
  // Exposing the mutable backing list through the `value` getter/setter allows
  // interop with the existing Workers API ([ever], [once], [debounce]).

  @override
  List<E> get value {
    if (Notifier.isTracking) reportRead();
    return _list;
  }

  /// Replaces the entire backing list and schedules exactly one notification.
  @override
  set value(List<E> newValue) {
    internalValue = List<E>.of(newValue);
    autoBatchRefresh();
  }

  // ─── Convenience helpers ───────────────────────────────────────────────────

  /// The unguarded backing list, suitable for non-reactive internal reads.
  /// Does NOT register a reactive dependency.
  List<E> get rawList => _list;

  @override
  String toString() => _list.toString();
}

// ─── Extension: List<E>.obs ───────────────────────────────────────────────────

extension RxListExt<E> on List<E> {
  /// Wraps this [List] in a reactive [RxList] observable.
  ///
  /// The more-specific `on List<E>` wins over the generic `RxT<T> on T`
  /// extension, so `<String>[].obs` correctly returns an [RxList<String>].
  ///
  /// ```dart
  /// final items = <String>[].obs;
  ///
  /// // Inside a loop — only ONE Obx rebuild fires:
  /// for (final s in source) {
  ///   items.add(s);
  /// }
  /// ```
  RxList<E> get obs => RxList<E>(this);
}

/// A reactive map with the same dirty-flag microtask batching, read fast-path
/// and Worker compatibility as [RxList].
///
/// ```dart
/// final prefs = <String, bool>{}.obs;
/// prefs['dark'] = true;          // one Obx rebuild
/// prefs.addAll({'a': true, 'b': false});
/// Obx(() => Text('${prefs['dark']}'));
/// ```
class RxMap<K, V> extends GetListenable<Map<K, V>>
    with MapMixin<K, V>, RxBatchNotifier<Map<K, V>> {
  /// Creates an [RxMap] pre-populated with [initial] entries.
  RxMap([Map<K, V>? initial]) : super(Map<K, V>.of(initial ?? <K, V>{}));

  Map<K, V> get _map => internalValue;

  // ─── MapMixin contract ─────────────────────────────────────────────────────

  @override
  V? operator [](Object? key) {
    if (Notifier.isTracking) reportRead();
    return _map[key];
  }

  @override
  void operator []=(K key, V value) {
    _map[key] = value;
    autoBatchRefresh();
  }

  @override
  V? remove(Object? key) {
    if (!_map.containsKey(key)) return null;
    final removed = _map.remove(key);
    autoBatchRefresh();
    return removed;
  }

  @override
  void clear() {
    if (_map.isEmpty) return;
    _map.clear();
    autoBatchRefresh();
  }

  @override
  Iterable<K> get keys {
    if (Notifier.isTracking) reportRead();
    return _map.keys;
  }

  // ─── Read overrides (avoid MapMixin's O(n) defaults via `keys`) ───────────

  @override
  Iterable<V> get values {
    if (Notifier.isTracking) reportRead();
    return _map.values;
  }

  @override
  Iterable<MapEntry<K, V>> get entries {
    if (Notifier.isTracking) reportRead();
    return _map.entries;
  }

  @override
  int get length {
    if (Notifier.isTracking) reportRead();
    return _map.length;
  }

  @override
  bool get isEmpty {
    if (Notifier.isTracking) reportRead();
    return _map.isEmpty;
  }

  @override
  bool get isNotEmpty {
    if (Notifier.isTracking) reportRead();
    return _map.isNotEmpty;
  }

  @override
  bool containsKey(Object? key) {
    if (Notifier.isTracking) reportRead();
    return _map.containsKey(key);
  }

  @override
  bool containsValue(Object? value) {
    if (Notifier.isTracking) reportRead();
    return _map.containsValue(value);
  }

  // ─── High-Level Mutators (single notification each) ────────────────────────

  @override
  void addAll(Map<K, V> other) {
    if (other.isEmpty) return;
    _map.addAll(other);
    autoBatchRefresh();
  }

  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    _map.addEntries(newEntries);
    autoBatchRefresh();
  }

  @override
  void removeWhere(bool Function(K key, V value) test) {
    final before = _map.length;
    _map.removeWhere(test);
    if (_map.length != before) autoBatchRefresh();
  }

  @override
  void updateAll(V Function(K key, V value) update) {
    _map.updateAll(update);
    autoBatchRefresh();
  }

  /// Replaces all entries with [other] in a single atomic operation.
  void assignAll(Map<K, V> other) {
    _map
      ..clear()
      ..addAll(other);
    autoBatchRefresh();
  }

  // ─── GetListenable value override ─────────────────────────────────────────

  @override
  Map<K, V> get value {
    if (Notifier.isTracking) reportRead();
    return _map;
  }

  @override
  set value(Map<K, V> newValue) {
    internalValue = Map<K, V>.of(newValue);
    autoBatchRefresh();
  }

  /// The unguarded backing map. Does NOT register a reactive dependency.
  Map<K, V> get rawMap => _map;

  @override
  String toString() => _map.toString();
}

// ─── Extension: Map<K, V>.obs ─────────────────────────────────────────────────

extension RxMapExt<K, V> on Map<K, V> {
  /// Wraps this [Map] in a reactive [RxMap] observable.
  RxMap<K, V> get obs => RxMap<K, V>(this);
}

/// A reactive set with the same dirty-flag microtask batching, read fast-path
/// and Worker compatibility as [RxList].
///
/// ```dart
/// final selected = <int>{}.obs;
/// selected.add(3);               // one Obx rebuild
/// Obx(() => Text('${selected.contains(3)}'));
/// ```
class RxSet<E> extends GetListenable<Set<E>>
    with SetMixin<E>, RxBatchNotifier<Set<E>> {
  /// Creates an [RxSet] pre-populated with [initial] elements.
  RxSet([Set<E>? initial]) : super(Set<E>.of(initial ?? <E>{}));

  Set<E> get _set => internalValue;

  // ─── SetMixin contract ─────────────────────────────────────────────────────

  @override
  bool add(E value) {
    final added = _set.add(value);
    if (added) autoBatchRefresh();
    return added;
  }

  @override
  bool contains(Object? element) {
    if (Notifier.isTracking) reportRead();
    return _set.contains(element);
  }

  @override
  E? lookup(Object? element) {
    if (Notifier.isTracking) reportRead();
    return _set.lookup(element);
  }

  @override
  bool remove(Object? value) {
    final removed = _set.remove(value);
    if (removed) autoBatchRefresh();
    return removed;
  }

  @override
  Iterator<E> get iterator {
    if (Notifier.isTracking) reportRead();
    return _set.iterator;
  }

  @override
  int get length {
    if (Notifier.isTracking) reportRead();
    return _set.length;
  }

  @override
  Set<E> toSet() {
    if (Notifier.isTracking) reportRead();
    return _set.toSet();
  }

  // ─── High-Level Mutators (single notification each) ────────────────────────

  @override
  void addAll(Iterable<E> elements) {
    final before = _set.length;
    _set.addAll(elements);
    if (_set.length != before) autoBatchRefresh();
  }

  @override
  void removeAll(Iterable<Object?> elements) {
    final before = _set.length;
    _set.removeAll(elements);
    if (_set.length != before) autoBatchRefresh();
  }

  @override
  void retainAll(Iterable<Object?> elements) {
    final before = _set.length;
    _set.retainAll(elements);
    if (_set.length != before) autoBatchRefresh();
  }

  @override
  void removeWhere(bool Function(E element) test) {
    final before = _set.length;
    _set.removeWhere(test);
    if (_set.length != before) autoBatchRefresh();
  }

  @override
  void retainWhere(bool Function(E element) test) {
    final before = _set.length;
    _set.retainWhere(test);
    if (_set.length != before) autoBatchRefresh();
  }

  @override
  void clear() {
    if (_set.isEmpty) return;
    _set.clear();
    autoBatchRefresh();
  }

  /// Replaces all elements with [elements] in a single atomic operation.
  void assignAll(Iterable<E> elements) {
    _set
      ..clear()
      ..addAll(elements);
    autoBatchRefresh();
  }

  // ─── GetListenable value override ─────────────────────────────────────────

  @override
  Set<E> get value {
    if (Notifier.isTracking) reportRead();
    return _set;
  }

  @override
  set value(Set<E> newValue) {
    internalValue = Set<E>.of(newValue);
    autoBatchRefresh();
  }

  /// The unguarded backing set. Does NOT register a reactive dependency.
  Set<E> get rawSet => _set;

  @override
  String toString() => _set.toString();
}

// ─── Extension: Set<E>.obs ────────────────────────────────────────────────────

extension RxSetExt<E> on Set<E> {
  /// Wraps this [Set] in a reactive [RxSet] observable.
  RxSet<E> get obs => RxSet<E>(this);
}
