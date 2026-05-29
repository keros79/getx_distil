import 'dart:async';
import 'dart:collection';
import 'dart:math' show Random;

import 'rx_core.dart';

/// A reactive list that coalesces high-frequency write operations into a single
/// UI notification per event-loop turn using a dirty-flag + microtask pipeline.
///
/// ### Batching Guarantee
/// Any number of mutating calls made synchronously within the same Dart event
/// (e.g., inside a `for` loop) will only schedule **one** microtask.  The
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
class RxList<E> extends GetListenable<List<E>> with ListMixin<E> {
  // ─── Construction ──────────────────────────────────────────────────────────

  /// Creates an [RxList] pre-populated with [initial] elements.
  RxList([List<E>? initial]) : super(List<E>.of(initial ?? <E>[]));

  // ─── Convenience shorthand ─────────────────────────────────────────────────

  /// The unguarded backing list via the @protected [internalValue] accessor.
  /// Use only for non-reactive internal mutations.
  List<E> get _list => internalValue;

  // ─── Dirty-Flag Microtask Batching ─────────────────────────────────────────

  /// Guards against redundant microtask scheduling.
  /// Acts as the "isDirty" state lock described in the architecture spec.
  bool _isNotificationScheduled = false;

  /// Core optimization gate.
  ///
  /// On the **first** mutating call within a synchronous frame:
  ///   1. [_isNotificationScheduled] is `false` → proceed.
  ///   2. Flip the flag to `true` so every subsequent call in the same frame
  ///      is a no-op (the redundant notification is **dropped**).
  ///   3. Schedule a microtask; inside it, call [refresh] once and reset the
  ///      flag, making the system ready for the next frame's mutations.
  void _autoBatchRefresh() {
    if (_isNotificationScheduled) return; // ← drop-path: already queued
    _isNotificationScheduled = true;
    scheduleMicrotask(() {
      refresh();        // Obx widget updaters
      notifyStream();   // ever / once / debounce stream workers
      _isNotificationScheduled = false;
    });
  }

  // ─── ListMixin contract ────────────────────────────────────────────────────
  //
  // [ListMixin] delegates ALL default List operations to the four primitives
  // below: `length` getter, `length` setter, `[]` operator, and `[]=`
  // operator. We intercept writes at []=, [length=], and at the high-level
  // mutators to route through [_autoBatchRefresh].

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
    _autoBatchRefresh();
  }

  @override
  E operator [](int index) {
    if (Notifier.isTracking) reportRead();
    return _list[index];
  }

  @override
  void operator []=(int index, E value) {
    _list[index] = value;
    _autoBatchRefresh();
  }

  // ─── High-Level Mutators ───────────────────────────────────────────────────

  @override
  void add(E element) {
    _list.add(element);
    _autoBatchRefresh();
  }

  @override
  void addAll(Iterable<E> iterable) {
    _list.addAll(iterable);
    _autoBatchRefresh();
  }

  @override
  bool remove(Object? element) {
    final removed = _list.remove(element);
    if (removed) _autoBatchRefresh();
    return removed;
  }

  @override
  E removeAt(int index) {
    final element = _list.removeAt(index);
    _autoBatchRefresh();
    return element;
  }

  @override
  void clear() {
    if (_list.isEmpty) return; // nothing changed → skip notification
    _list.clear();
    _autoBatchRefresh();
  }

  /// Replaces all contents with [iterable] in a single atomic operation.
  ///
  /// Regardless of how many elements are swapped in, exactly **one**
  /// microtask is scheduled, guaranteeing one [Obx] rebuild.
  void assignAll(Iterable<E> iterable) {
    _list
      ..clear()
      ..addAll(iterable);
    _autoBatchRefresh();
  }

  /// Sorts the list in-place and schedules exactly **one** notification,
  /// bypassing the per-swap `[]=` hot-path that [ListMixin] would otherwise use.
  @override
  void sort([int Function(E a, E b)? compare]) {
    _list.sort(compare);
    _autoBatchRefresh();
  }

  /// Shuffles the list in-place and schedules exactly **one** notification,
  /// bypassing the per-swap `[]=` hot-path that [ListMixin] would otherwise use.
  @override
  void shuffle([Random? random]) {
    _list.shuffle(random);
    _autoBatchRefresh();
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
    _autoBatchRefresh();
  }

  // ─── Convenience helpers ───────────────────────────────────────────────────

  /// The unguarded backing list, suitable for non-reactive internal reads.
  /// Does NOT register a reactive dependency.
  List<E> get rawList => _list;

  @override
  String toString() => _list.toString();

  /// Disposes all listeners and the stream controller.
  ///
  /// Also resets [_isNotificationScheduled] so that any microtask already
  /// queued before [close] was called becomes a safe no-op — it will still
  /// run but [refresh] and [notifyStream] will find empty listener lists.
  @override
  void close() {
    _isNotificationScheduled = false; // cancel zombie microtask flag
    super.close();
  }
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
