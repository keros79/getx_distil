import 'package:flutter/widgets.dart';

mixin GetLifeCycleMixin {
  bool _initialized = false;
  bool get initialized => _initialized;

  bool _isClosed = false;
  bool get isClosed => _isClosed;

  @mustCallSuper
  void onInit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isClosed) {
        onReady();
      }
    });
  }

  void onReady() {}

  void onClose() {}

  @mustCallSuper
  void onStart() {
    if (_initialized) return;
    onInit();
    _initialized = true;
  }

  @mustCallSuper
  void onDelete() {
    if (_isClosed) return;
    _isClosed = true;
    onClose();
  }
}

/// Base class for controllers driven by the imperative `update()` API and
/// consumed through [GetBuilder].
///
/// Listeners come in two flavours, mirroring GetX:
///
/// * **Global listeners** ([addListener]) are notified by `update()` without
///   ids, or by [refresh].
/// * **Id-scoped listeners** ([addListenerId]) are notified only by
///   `update(['thatId'])` or [refreshGroup]. A `GetBuilder(id: 'x')` registers
///   an id-scoped listener, so `update()` with no ids does **not** rebuild it.
abstract class GetxController with GetLifeCycleMixin {
  final List<VoidCallback> _updaters = [];
  final Map<Object, List<VoidCallback>> _updatersGroupIds = {};

  /// Rebuilds the widgets listening to this controller.
  ///
  /// * `update()` → notifies every **global** listener (`GetBuilder` without
  ///   an `id`).
  /// * `update(['a', 'b'])` → notifies only the listeners registered for
  ///   ids `'a'` and `'b'` (`GetBuilder(id: 'a')`, …). Global listeners are
  ///   left untouched.
  /// * [condition] `false` → no-op.
  void update([List<Object>? ids, bool condition = true]) {
    if (!condition) return;
    if (ids == null) {
      refresh();
      return;
    }
    for (final id in ids) {
      refreshGroup(id);
    }
  }

  /// Notifies every global listener. Equivalent to `update()`.
  void refresh() {
    final list = List<VoidCallback>.of(_updaters);
    for (final updater in list) {
      updater();
    }
  }

  /// Notifies only the listeners registered under [id].
  void refreshGroup(Object id) {
    final group = _updatersGroupIds[id];
    if (group == null || group.isEmpty) return;
    final list = List<VoidCallback>.of(group);
    for (final updater in list) {
      updater();
    }
  }

  /// Registers a global listener. Returns a disposer that removes it.
  VoidCallback addListener(VoidCallback listener) {
    _updaters.add(listener);
    return () => _updaters.remove(listener);
  }

  void removeListener(VoidCallback listener) {
    _updaters.remove(listener);
  }

  /// Registers a listener that is only notified by `update([id])` /
  /// [refreshGroup]. Returns a disposer that removes it.
  VoidCallback addListenerId(Object id, VoidCallback listener) {
    _updatersGroupIds.putIfAbsent(id, () => <VoidCallback>[]).add(listener);
    return () => removeListenerId(id, listener);
  }

  void removeListenerId(Object id, VoidCallback listener) {
    final group = _updatersGroupIds[id];
    if (group == null) return;
    group.remove(listener);
    if (group.isEmpty) _updatersGroupIds.remove(id);
  }

  /// Removes every listener registered under [id].
  void disposeId(Object id) {
    _updatersGroupIds.remove(id);
  }

  /// Whether any listener (global or id-scoped) is attached.
  bool get hasListeners =>
      _updaters.isNotEmpty || _updatersGroupIds.isNotEmpty;

  @override
  @mustCallSuper
  void onClose() {
    _updaters.clear();
    _updatersGroupIds.clear();
  }
}

abstract class GetxService with GetLifeCycleMixin {}
