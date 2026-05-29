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

class _DebounceWorker<T> extends Worker {
  final StreamSubscription<T> _subscription;
  final VoidCallback _cancelTimer;

  _DebounceWorker(this._subscription, this._cancelTimer);

  @override
  void dispose() {
    _subscription.cancel();
    _cancelTimer();
  }
}

/// Fires [callback] every time [listener] changes its value.
Worker ever<T>(RxInterface<T> listener, void Function(T value) callback) {
  final subscription = listener.listen(callback);
  return _StreamWorker<T>(subscription);
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

  return _DebounceWorker<T>(subscription, () => debounceTimer?.cancel());
}
