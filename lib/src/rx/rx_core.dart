import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

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
      [GetX] The improper use of Obx has been detected.
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
  List<StreamSubscription<T>>? _boundSubscriptions;

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
    final scheduler = SchedulerBinding.instance;
    final phase = scheduler.schedulerPhase;

    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      scheduler.addPostFrameCallback((_) {
        for (final updater in list) {
          updater();
        }
      });
    } else {
      for (final updater in list) {
        updater();
      }
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

  /// Forwards [error] to the broadcast stream **only if** a consumer is
  /// already attached (a Worker or a manual [listen]).
  ///
  /// Returns `true` when the error was delivered to at least one listener.
  /// Callers use the return value to decide whether the error still has to
  /// be surfaced elsewhere, so errors are never swallowed by an empty
  /// broadcast stream.
  @protected
  bool notifyStreamError(Object error, [StackTrace? stackTrace]) {
    final controller = _controller;
    if (controller == null || !controller.hasListener) return false;
    controller.addError(error, stackTrace);
    return true;
  }

  /// Binds this observable to an external [stream].
  ///
  /// Every event emitted by [stream] is assigned to [value], triggering the
  /// usual reactive notifications. The subscription is owned by this
  /// observable and is cancelled automatically on [close]; call
  /// [unbindStreams] to cancel earlier.
  ///
  /// ```dart
  /// final ticks = 0.obs;
  /// ticks.bindStream(Stream.periodic(const Duration(seconds: 1), (i) => i));
  /// ```
  void bindStream(Stream<T> stream) {
    final subs = _boundSubscriptions ??= <StreamSubscription<T>>[];
    subs.add(stream.listen((event) => value = event));
  }

  /// Cancels every subscription created by [bindStream].
  void unbindStreams() {
    final subs = _boundSubscriptions;
    if (subs == null) return;
    for (final sub in subs) {
      sub.cancel();
    }
    subs.clear();
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
    unbindStreams();
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
          '[GetX] Obx builder returned a Future. The Obx builder must be completely synchronous.\n'
          'Reading reactive variables inside an asynchronous block (like async/await or Future callbacks) '
          'causes reactive dependencies to be registered outside the active tracking frame, '
          'leading to untracked state updates and UI sync bugs.\n'
          'Avoid using async/await inside Obx. If you need asynchronous initialization, '
          'fetch the data inside your Controller\'s onInit() or onReady() instead.',
        );
      }
      if (data.disposers.isEmpty && data.throwException) {
        assert(() {
          debugPrint(
            '[GetX] Warning: No observable variables (Rx) were detected inside Obx. '
            'This Obx widget will behave like a static widget and will not rebuild on state changes.'
          );
          return true;
        }());
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
