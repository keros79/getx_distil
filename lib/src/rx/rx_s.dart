import 'package:flutter/widgets.dart';
import 'rx_types.dart';
import '../state_manager/obx.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// RxDataStatus
/// ─────────────────────────────────────────────────────────────────────────────
/// Represents the four fundamental states of an asynchronous data value.
enum RxDataStatus { idle, loading, loaded, error }

/// ─────────────────────────────────────────────────────────────────────────────
/// RxS\<T\>
/// ─────────────────────────────────────────────────────────────────────────────
/// An [Rxn] (nullable reactive value) that carries its own idle/loading/loaded/error
/// status alongside the reactive data, so consumers never have to maintain a
/// separate status observable.
///
/// ### Design Philosophy
///
/// **Use Rx value APIs directly — status tracks automatically.**
///
/// Every mutating operation (`value` setter, `update`) is overridden to call
/// `_syncStatus()` after the mutation, so the status automatically transitions
/// to [RxDataStatus.loaded].
///
/// The [RxDataStatus.error] state is **never** set automatically — it must be
/// assigned manually via the [status] setter. This prevents unintended status
/// transitions when an error occurs while the data still holds a valid value.
///
/// ### Usage
/// ```dart
/// final user = RxS<User?>(null);
///
/// // ── Data loading ────────────────────────────────────────────────
/// user.value = User(name: 'Alice');  // status → loaded
///
/// // ── Error handling ──────────────────────────────────────────────
/// user.error = 'Network failure';
/// user.status = RxDataStatus.error;
///
/// // ── UI binding ──────────────────────────────────────────────────
/// user.on(
///   idle: () => const Text('Idle'),
///   loading: () => const CircularProgressIndicator(),
///   loaded:  (data) => Text('Hello, ${data?.name ?? "Guest"}'),
///   error:   (msg) => Text('Error: $msg'),
/// );
/// ```
class RxS<T> extends Rxn<T> {
  // ─── Status ────────────────────────────────────────────────────────────────

  /// Internal status observable — read via [status] getter, mutated via
  /// the [status] setter for clean DX.
  final Rx<RxDataStatus> _status;

  /// The current status of this reactive value.
  RxDataStatus get status => _status.value;

  /// Setter-based status mutation for DX simplicity.
  ///
  /// ```dart
  /// user.status = RxDataStatus.loading; // triggers Obx rebuild
  /// ```
  set status(RxDataStatus newStatus) => _status.value = newStatus;

  /// Internal error message observable.
  final Rxn<String> _error = Rxn<String>();

  /// Holds the error message when [status] is [RxDataStatus.error].
  String? get error => _error.value;
  set error(String? val) => _error.value = val;

  // ─── Construction ──────────────────────────────────────────────────────────

  /// Creates an [RxS] optionally initialized with [initial] value.
  ///
  /// - No initial value (or `null`) → status starts as [RxDataStatus.idle],
  ///   so the UI shows an idle state until the first mutation or status change.
  /// - A non-null [initial] value → status starts as [RxDataStatus.loaded],
  ///   because data is already present (e.g. `User(...).ops`).
  RxS([super.initial])
      : _status = Rx<RxDataStatus>(
          initial == null ? RxDataStatus.idle : RxDataStatus.loaded,
        );

  // ─── Status Mutator Helpers ────────────────────────────────────────────────

  /// Transitions the status to [RxDataStatus.idle].
  void setIdle() => status = RxDataStatus.idle;

  /// Transitions the status to [RxDataStatus.loading].
  void setLoading() => status = RxDataStatus.loading;

  /// Transitions the status to [RxDataStatus.loaded].
  void setLoaded() => status = RxDataStatus.loaded;

  /// Sets the error message and transitions the status to [RxDataStatus.error].
  void setError(String? errorMsg) {
    error = errorMsg;
    status = RxDataStatus.error;
  }

  // ─── Async loading ─────────────────────────────────────────────────────────

  /// Monotonic token so that only the **latest** [load] call may apply its
  /// result; earlier, slower calls are discarded (last-write-wins).
  int _loadToken = 0;

  /// Runs [fetch] and drives [status] automatically:
  ///
  /// * `loading` while the future is pending (the current [value] is
  ///   preserved underneath),
  /// * `loaded` with the fetched value on success,
  /// * `error` (via [setError]) on failure — the previous value is kept.
  ///
  /// Errors are captured into the status instead of being thrown, so the
  /// returned future always completes normally. They are additionally
  /// forwarded to attached stream consumers (`ever(onError:)`, `listen`).
  ///
  /// When several [load] calls overlap, only the most recent one is allowed to
  /// update the state; stale results are ignored.
  ///
  /// ```dart
  /// final user = RxS<User?>(null);
  /// await user.load(() => api.fetchUser());        // idle → loading → loaded
  /// await user.load(() => throw 'offline');        // → error ('offline')
  /// ```
  Future<void> load(
    Future<T?> Function() fetch, {
    String Function(Object error)? errorMessage,
  }) async {
    final token = ++_loadToken;
    status = RxDataStatus.loading;
    try {
      final result = await fetch();
      if (token != _loadToken) return; // superseded by a newer load()
      value = result; // → loaded
    } catch (e, s) {
      if (token != _loadToken) return;
      notifyStreamError(e, s);
      setError(errorMessage != null ? errorMessage(e) : e.toString());
    }
  }

  // ─── Internal: auto-sync status after mutation ─────────────────────────────

  /// Called after every mutating operation to keep [status] in sync with
  /// the data content.
  ///
  /// Rules:
  /// - Any value mutation → [RxDataStatus.loaded].
  /// - Any active error state is cleared.
  void _syncStatus() {
    _error.value = null;
    _status.value = RxDataStatus.loaded;
  }

  // ─── Override: Rxn mutators → auto-sync status ────────────────────────────

  @override
  set value(T? newValue) {
    super.value = newValue;
    _syncStatus();
  }

  @override
  void update(T? Function(T? val) fn) {
    super.update(fn);
    _syncStatus();
  }
}

// ─── Extension: .ops — T → RxS<T> ────────────────────────────────────────────

extension RxSOpsExt<T> on T {
  /// Converts a plain value into an [RxS].
  ///
  /// A non-null value starts as [RxDataStatus.loaded]; a `null` value starts
  /// as [RxDataStatus.idle].
  ///
  /// ```dart
  /// final user = User(name: 'Alice').ops; // status: loaded
  /// final none = (null as User?).ops;      // status: idle
  /// ```
  RxS<T> get ops => RxS<T>(this);
}

// ─── Extension: .on — RxS<T> → status-based widget builder ───────────────────

extension RxSOnExt<T> on RxS<T> {
  /// Builds a widget that switches on [RxS.status].
  ///
  /// Only the [loaded] callback is wrapped in an internal `Obx` so that value
  /// mutations automatically trigger a rebuild while the status is `loaded`.
  /// Status transitions (`loading→loaded`, `loaded→error`, etc.) are handled
  /// by wrapping with an outer `Obx`:
  ///
  /// ```dart
  /// Obx(() => user.on(
  ///   idle: () => const Center(child: Text('Idle')),
  ///   loading: () => const Center(child: CircularProgressIndicator()),
  ///   loaded:  (data) => Text('Hello, ${data?.name ?? "Guest"}'),
  ///   error:   (msg) => Center(child: Text('Oops: $msg')),
  /// ));
  /// ```
  Widget on({
    Widget Function()? idle,
    required Widget Function() loading,
    required Widget Function(T? data) loaded,
    Widget Function(String? error)? error,
  }) {
    switch (_status.value) {
      case RxDataStatus.idle:
        return idle != null ? idle() : const SizedBox.shrink();
      case RxDataStatus.loading:
        return loading();
      case RxDataStatus.loaded:
        // Wrap with Obx so that value mutations in loaded state
        // trigger a rebuild. Wrap with Obx(() => value.on(...)) on the page
        // to detect status transitions.
        return Obx(() {
          final reactiveValue = value; // touch Rx.value to subscribe
          return loaded(reactiveValue);
        });
      case RxDataStatus.error:
        return error != null
            ? Obx(() => error(this.error))
            : const SizedBox.shrink();
    }
  }
}
