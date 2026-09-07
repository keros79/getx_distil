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
  final Rx<RxListStatus> _status;

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
  /// - No initial list, or an empty one → status starts as
  ///   [RxListStatus.idle], so the UI shows an idle state until the first
  ///   data mutation (an empty *initial* list has not been "loaded" yet).
  /// - A non-empty [initial] list → status starts as [RxListStatus.loaded],
  ///   because data is already present.
  RxSList([super.initial])
      : _status = Rx<RxListStatus>(
          (initial == null || initial.isEmpty)
              ? RxListStatus.idle
              : RxListStatus.loaded,
        );

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
  void setError(String? errorMsg) {
    error = errorMsg;
    status = RxListStatus.error;
  }

  // ─── Async loading ─────────────────────────────────────────────────────────

  /// Monotonic token so that only the **latest** [load] call may apply its
  /// result; earlier, slower calls are discarded (last-write-wins).
  int _loadToken = 0;

  /// Runs [fetch] and drives [status] automatically:
  ///
  /// * `loading` while the future is pending (current items are preserved
  ///   underneath),
  /// * `loaded` / `empty` after [assignAll] with the fetched items,
  /// * `error` (via [setError]) on failure — the previous items are kept.
  ///
  /// Errors are captured into the status instead of being thrown, so the
  /// returned future always completes normally. They are additionally
  /// forwarded to attached stream consumers (`ever(onError:)`, `listen`).
  ///
  /// When several [load] calls overlap, only the most recent one is allowed to
  /// update the state; stale results are ignored.
  ///
  /// ```dart
  /// final users = <User>[].ops;
  /// await users.load(() => api.fetchUsers());   // idle → loading → loaded/empty
  /// ```
  Future<void> load(
    Future<Iterable<T>> Function() fetch, {
    String Function(Object error)? errorMessage,
  }) async {
    final token = ++_loadToken;
    status = RxListStatus.loading;
    try {
      final result = await fetch();
      if (token != _loadToken) return; // superseded by a newer load()
      assignAll(result); // → loaded / empty
    } catch (e, s) {
      if (token != _loadToken) return;
      notifyStreamError(e, s);
      setError(errorMessage != null ? errorMessage(e) : e.toString());
    }
  }

  /// Fetches the **next page** with [fetchNext] and appends it.
  ///
  /// Unlike [load], the status is **not** switched to `loading`, so the
  /// already-visible items stay on screen while the page is fetched. After the
  /// page arrives it is appended with [addAll] and [hasMore] is set to whether
  /// the page contained any items. On failure [setError] is called and the
  /// existing items are kept.
  ///
  /// Does nothing (completes immediately) when [hasMore] is already `false`.
  ///
  /// ```dart
  /// await users.load(() => api.fetchUsers(page: 0));
  /// ...
  /// await users.loadMore(() => api.fetchUsers(page: ++page));
  /// ```
  Future<void> loadMore(
    Future<Iterable<T>> Function() fetchNext, {
    String Function(Object error)? errorMessage,
  }) async {
    if (!hasMore) return;
    try {
      final page = await fetchNext();
      final items = page.toList(growable: false);
      if (items.isNotEmpty) addAll(items);
      hasMore = items.isNotEmpty;
    } catch (e, s) {
      notifyStreamError(e, s);
      setError(errorMessage != null ? errorMessage(e) : e.toString());
    }
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
  /// Converts a plain [List] into an [RxSList].
  ///
  /// An empty list starts as [RxListStatus.idle]; a non-empty list starts as
  /// [RxListStatus.loaded].
  ///
  /// ```dart
  /// final items = <String>[].ops;
  /// print(items.status); // RxListStatus.idle
  ///
  /// final seeded = ['a', 'b'].ops;
  /// print(seeded.status); // RxListStatus.loaded
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
    Widget Function(String? error)? error,
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
            ? Obx(() => error(this.error))
            : const SizedBox.shrink();
    }
  }
}
