import 'package:flutter/widgets.dart';
import 'rx_collections.dart';
import 'rx_types.dart';
import '../state_manager/obx.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// RxListStatus
/// ─────────────────────────────────────────────────────────────────────────────
/// Represents the five fundamental states of an asynchronous data list.
enum RxListStatus { idle, loading, loaded, empty, error }

/// ─────────────────────────────────────────────────────────────────────────────
/// RxSList\<T\>
/// ─────────────────────────────────────────────────────────────────────────────
/// An [RxList] that carries its own idle/loading/loaded/empty/error status alongside
/// the reactive list data, so consumers never have to maintain a separate
/// status observable.
///
/// ### Design Philosophy
///
/// **Use RxList APIs directly — status tracks automatically.**
///
/// Every mutating method inherited from [RxList] (`add`, `addAll`, `assignAll`,
/// `remove`, `removeAt`, `clear`, `value` setter) is overridden to call
/// `_syncStatus()` after the mutation, so the status automatically reflects
/// whether the list is [RxListStatus.empty] or [RxListStatus.loaded].
///
/// The [RxListStatus.error] state is **never** set automatically — it must be
/// assigned manually via the [status] setter. This prevents unintended status
/// transitions when an error occurs while the list still holds valid data.
///
/// ### Paging Support
///
/// Use [hasMore] to indicate whether additional pages are available. Combine
/// with [addAll] to append pages:
///
/// ```dart
/// // First page
/// items.assignAll(page1);          // status → loaded
/// items.hasMore = page1.isNotEmpty;
///
/// // Next page
/// items.addAll(page2);             // status stays loaded
/// items.hasMore = page2.isNotEmpty;
/// ```
///
/// ### Usage
/// ```dart
/// final items = <String>[].ops;
///
/// // ── Data loading ────────────────────────────────────────────────
/// items.assignAll(['apple', 'banana']);  // status → loaded
/// items.add('cherry');                   // status stays loaded
/// items.clear();                         // status → empty
///
/// // ── Error handling ──────────────────────────────────────────────
/// items.error = 'Network failure';
/// items.status = RxListStatus.error;
///
/// // ── UI binding ──────────────────────────────────────────────────
/// items.on(
///   idle: () => const Text('Idle'),
///   loading: () => const CircularProgressIndicator(),
///   loaded:  (data) => ListView.builder(...),
///   empty:   () => const Text('No items'),
///   error:   (msg) => Text('Error: $msg'),
/// );
/// ```
class RxSList<T> extends RxList<T> {
  // ─── Status ────────────────────────────────────────────────────────────────

  /// Internal status observable — read via [status] getter, mutated via
  /// the [status] setter for clean DX.
  final Rx<RxListStatus> _status = Rx<RxListStatus>(RxListStatus.idle);

  /// The current status of this list.
  RxListStatus get status => _status.value;

  /// Setter-based status mutation for DX simplicity.
  ///
  /// ```dart
  /// items.status = RxListStatus.loading; // triggers Obx rebuild
  /// ```
  set status(RxListStatus newStatus) => _status.value = newStatus;

  /// Internal error message observable.
  final Rxn<String> _error = Rxn<String>();

  /// Holds the error message when [status] is [RxListStatus.error].
  String? get error => _error.value;
  set error(String? val) => _error.value = val;

  // ─── Paging ────────────────────────────────────────────────────────────────

  /// Whether more pages are available for this list.
  ///
  /// Set to `false` when the last page has been loaded. Combine with [addAll]
  /// to implement infinite-scroll pagination:
  ///
  /// ```dart
  /// items.addAll(nextPage);
  /// items.hasMore = nextPage.isNotEmpty;
  /// ```
  final Rx<bool> _hasMore = Rx<bool>(true);
  bool get hasMore => _hasMore.value;
  set hasMore(bool v) => _hasMore.value = v;

  // ─── Construction ──────────────────────────────────────────────────────────

  /// Creates an [RxSList] optionally pre-populated with [initial] elements.
  ///
  /// The initial status is [RxListStatus.idle] by default so that the
  /// UI shows an idle state until the first data mutation.
  RxSList([super.initial]);

  // ─── Status Mutator Helpers ────────────────────────────────────────────────

  /// Transitions the status to [RxListStatus.idle].
  void setIdle() => status = RxListStatus.idle;

  /// Transitions the status to [RxListStatus.loading].
  void setLoading() => status = RxListStatus.loading;

  /// Transitions the status to [RxListStatus.loaded].
  void setLoaded() => status = RxListStatus.loaded;

  /// Transitions the status to [RxListStatus.empty].
  void setEmpty() => status = RxListStatus.empty;

  /// Sets the error message and transitions the status to [RxListStatus.error].
  void setError(String errorMsg) {
    error = errorMsg;
    status = RxListStatus.error;
  }

  // ─── Internal: auto-sync status after mutation ─────────────────────────────

  /// Called after every mutating operation to keep [status] in sync with
  /// the list content.
  ///
  /// Rules:
  /// - If the list is empty → [RxListStatus.empty].
  /// - If the list has data → [RxListStatus.loaded].
  /// - Any active error state is cleared.
  void _syncStatus() {
    _error.value = null;
    _status.value = isEmpty ? RxListStatus.empty : RxListStatus.loaded;
  }

  // ─── Override: RxList mutators → auto-sync status ──────────────────────────

  @override
  void add(T element) {
    super.add(element);
    _syncStatus();
  }

  @override
  void addAll(Iterable<T> iterable) {
    super.addAll(iterable);
    _syncStatus();
  }

  @override
  void assignAll(Iterable<T> iterable) {
    super.assignAll(iterable);
    _syncStatus();
  }

  @override
  bool remove(Object? element) {
    final result = super.remove(element);
    _syncStatus();
    return result;
  }

  @override
  T removeAt(int index) {
    final result = super.removeAt(index);
    _syncStatus();
    return result;
  }

  @override
  void clear() {
    super.clear();
    _syncStatus();
  }

  @override
  set value(List<T> newValue) {
    super.value = newValue;
    _syncStatus();
  }
}

// ─── Extension: .ops — List<T> → RxSList<T> ───────────────────────────────────

extension RxSListOpsExt<T> on List<T> {
  /// Converts a plain [List] into an [RxSList] with initial [RxListStatus.idle].
  ///
  /// ```dart
  /// final items = <String>[].ops;
  /// print(items.status); // RxListStatus.idle
  /// ```
  RxSList<T> get ops => RxSList<T>(this);
}

// ─── Extension: .on — RxSList<T> → status-based widget builder ─────────────────

extension RxSListOnExt<T> on RxSList<T> {
  /// Builds a widget that switches on [RxSList.status].
  ///
  /// Only the [loaded] callback is wrapped in an internal `Obx` so that list
  /// mutations (`add`, `remove`, etc.) automatically trigger a rebuild while
  /// the list is in `loaded` state. Status transitions (`loading→loaded`,
  /// `loaded→empty`, etc.) are handled by wrapping with an outer `Obx`:
  ///
  /// ```dart
  /// Obx(() => items.on(
  ///   idle: () => const Center(child: Text('Idle')),
  ///   loading: () => const Center(child: CircularProgressIndicator()),
  ///   loaded:  (data) => ListView.builder(
  ///     itemCount: data.length,
  ///     itemBuilder: (_, i) => Text(data[i]),
  ///   ),
  ///   empty:   () => const Center(child: Text('No items')),
  ///   error:   (msg) => Center(child: Text('Oops: $msg')),
  /// ));
  /// ```
  Widget on({
    Widget Function()? idle,
    required Widget Function() loading,
    required Widget Function(List<T> data) loaded,
    Widget Function()? empty,
    Widget Function(String error)? error,
  }) {
    switch (_status.value) {
      case RxListStatus.idle:
        return idle != null ? idle() : const SizedBox.shrink();
      case RxListStatus.loading:
        return loading();
      case RxListStatus.loaded:
        // Wrap with Obx so that list mutations (add/remove) in loaded state
        // trigger a rebuild. Wrap with Obx(() => list.on(...)) on the page
        // to detect status transitions.
        return Obx(() {
          final reactiveValue = value; // touch Rx.value to subscribe
          return loaded(reactiveValue);
        });
      case RxListStatus.empty:
        return empty != null ? empty() : const SizedBox.shrink();
      case RxListStatus.error:
        return error != null
            ? Obx(() => error(this.error ?? 'Unknown error'))
            : const SizedBox.shrink();
    }
  }
}
