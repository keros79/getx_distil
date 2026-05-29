import 'dart:async';
import 'package:flutter/foundation.dart';

typedef Disposer = void Function();
typedef GetStateUpdate = void Function();

abstract class RxInterface<T> implements ValueListenable<T> {
  void close();
  StreamSubscription<T> listen(void Function(T event) onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError});
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
