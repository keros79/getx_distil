import 'dart:async';
import 'package:flutter/foundation.dart';

typedef Disposer = void Function();
typedef GetStateUpdate = void Function();

abstract class RxInterface<T> implements ValueListenable<T> {
  void close();
  StreamSubscription<T> listen(
    void Function(T event) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  });
}

class ObxError implements Exception {
  const ObxError();

  @override
  String toString() {
    return """
      [GetX Distil] The improper use of Obx has been detected.
      You must insert at least one observable variable (Rx) into the Obx build scope, 
      otherwise it has no dependencies to rebuild on change.
      """;
  }
}

class GetListenable<T> implements RxInterface<T> {
  GetListenable(this._value);
  T _value;

  /// Unguarded accessor for subclasses — bypasses [reportRead] and the
  /// equality guard so that mutations can be applied directly to the backing
  /// value before routing through [refresh].
  @protected
  T get internalValue => _value;

  @protected
  set internalValue(T v) => _value = v;

  StreamController<T>? _controller;
  final List<GetStateUpdate> _updaters = [];

  StreamController<T> get subject {
    if (_controller == null) {
      _controller = StreamController<T>.broadcast();
      _controller!.add(_value);
    }
    return _controller!;
  }

  Stream<T> get stream => subject.stream;

  @override
  T get value {
    reportRead();
    return _value;
  }

  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    _notify();
  }

  void _notify() {
    refresh();
    if (_controller != null) {
      _controller!.add(_value);
    }
  }

  void refresh() {
    final list = List<GetStateUpdate>.from(_updaters);
    for (final updater in list) {
      updater();
    }
  }

  /// Emits the current [_value] to the broadcast stream **only if** the
  /// stream controller already exists (i.e. a consumer called [listen] or
  /// accessed [stream]). Safe to call when no workers are active — it is a
  /// no-op in that case and avoids creating the controller unnecessarily.
  @protected
  void notifyStream() {
    if (_controller != null) {
      _controller!.add(_value);
    }
  }

  void reportRead() {
    if (Notifier.isTracking) {
      Notifier.instance.read(this);
    }
  }

  void reportAdd(VoidCallback disposer) {
    if (Notifier.isTracking) {
      Notifier.instance.add(disposer);
    }
  }

  @override
  Disposer addListener(GetStateUpdate listener) {
    _updaters.add(listener);
    return () => _updaters.remove(listener);
  }

  bool containsListener(GetStateUpdate listener) {
    return _updaters.contains(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _updaters.remove(listener);
  }

  @override
  StreamSubscription<T> listen(
    void Function(T event) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError ?? false,
    );
  }

  @override
  void close() {
    _controller?.close();
    _updaters.clear();
  }
}

class Notifier {
  Notifier._();
  static Notifier? _instance;
  static Notifier get instance => _instance ??= Notifier._();

  // High-performance CPU-friendly fast-path tracking flag
  static bool isTracking = false;
  static int _trackingCount = 0;

  NotifyData? _notifyData;

  void add(VoidCallback listener) {
    _notifyData?.disposers.add(listener);
  }

  void read(GetListenable listenable) {
    final listener = _notifyData?.updater;
    if (listener != null && !listenable.containsListener(listener)) {
      listenable.addListener(listener);
      add(() => listenable.removeListener(listener));
    }
  }

  R append<R>(NotifyData data, R Function() builder) {
    final oldNotifyData = _notifyData;
    _notifyData = data;

    _trackingCount++;
    isTracking = true;

    try {
      final result = builder();
      if (result is Future) {
        throw FlutterError(
          '[getx] Obx builder returned a Future. The Obx builder must be completely synchronous.\n'
          'Reading reactive variables inside an asynchronous block (like async/await or Future callbacks) '
          'causes reactive dependencies to be registered outside the active tracking frame, '
          'leading to untracked state updates and UI sync bugs.\n'
          'Avoid using async/await inside Obx. If you need asynchronous initialization, '
          'fetch the data inside your Controller\'s onInit() or onReady() instead.',
        );
      }
      if (data.disposers.isEmpty && data.throwException) {
        throw const ObxError();
      }
      return result;
    } finally {
      _notifyData = oldNotifyData;
      _trackingCount--;
      if (_trackingCount <= 0) {
        isTracking = false;
      }
    }
  }
}

class NotifyData {
  NotifyData({
    required this.updater,
    required this.disposers,
    this.throwException = true,
  });
  final GetStateUpdate updater;
  final List<VoidCallback> disposers;
  final bool throwException;
}
