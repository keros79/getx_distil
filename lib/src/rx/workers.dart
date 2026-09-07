import 'dart:async';
import 'package:flutter/foundation.dart';
import 'rx_core.dart';

abstract class Worker {
  void dispose();
  void cancel() => dispose();
}

class _StreamWorker<T> extends Worker {
  final StreamSubscription<T> _subscription;

  _StreamWorker(this._subscription);

  @override
  void dispose() {
    _subscription.cancel();
  }
}

class _TimerWorker<T> extends Worker {
  final StreamSubscription<T> _subscription;
  final VoidCallback _cancelTimer;

  _TimerWorker(this._subscription, this._cancelTimer);

  @override
  void dispose() {
    _subscription.cancel();
    _cancelTimer();
  }
}

class _MultiWorker extends Worker {
  final List<StreamSubscription<dynamic>> _subscriptions;

  _MultiWorker(this._subscriptions);

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
  }
}

/// Fires [callback] every time [listener] changes its value.
///
/// Pass [onError] to observe errors emitted by the observable (for example an
/// exception thrown inside `Rx.updateSequential`).
Worker ever<T>(
  RxInterface<T> listener,
  void Function(T value) callback, {
  Function? onError,
}) {
  final subscription = listener.listen(callback, onError: onError);
  return _StreamWorker<T>(subscription);
}

/// Fires [callback] every time **any** of [listeners] changes its value.
/// The callback receives the changed value.
Worker everAll(
  List<RxInterface<dynamic>> listeners,
  void Function(dynamic value) callback, {
  Function? onError,
}) {
  final subscriptions = listeners
      .map((l) => l.listen(callback, onError: onError))
      .toList(growable: false);
  return _MultiWorker(subscriptions);
}

/// Fires [callback] only once when [listener] changes its value.
/// Automatically disposes itself after the first execution.
Worker once<T>(RxInterface<T> listener, void Function(T value) callback) {
  late final StreamSubscription<T> subscription;
  subscription = listener.listen((value) {
    callback(value);
    subscription.cancel();
  });
  return _StreamWorker<T>(subscription);
}

/// Fires [callback] only after a period of silence (inactivity) on [listener].
/// Useful for suppressing high-frequency data surges or user search inputs.
Worker debounce<T>(
  RxInterface<T> listener,
  void Function(T value) callback, {
  Duration? time,
}) {
  final duration = time ?? const Duration(milliseconds: 800);
  Timer? debounceTimer;

  final subscription = listener.listen((value) {
    debounceTimer?.cancel();
    debounceTimer = Timer(duration, () {
      callback(value);
    });
  });

  return _TimerWorker<T>(subscription, () => debounceTimer?.cancel());
}

/// Rate-limits [listener]: fires [callback] at most once per [time].
///
/// The **first** change inside a window is captured; every further change
/// during the same window is ignored, and [callback] is invoked with the
/// captured value once the window elapses. Ideal for buttons that must not be
/// double-tapped or for throttling scroll/pointer streams.
Worker interval<T>(
  RxInterface<T> listener,
  void Function(T value) callback, {
  Duration time = const Duration(seconds: 1),
}) {
  Timer? intervalTimer;

  final subscription = listener.listen((value) {
    if (intervalTimer?.isActive ?? false) return; // window still open → drop
    intervalTimer = Timer(time, () {
      callback(value);
    });
  });

  return _TimerWorker<T>(subscription, () => intervalTimer?.cancel());
}
