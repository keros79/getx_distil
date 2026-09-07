import 'dart:async';
import 'rx_core.dart';

abstract class _RxImpl<T> extends GetListenable<T> {
  _RxImpl(super.initial);

  void addError(Object error, [StackTrace? stackTrace]) {
    subject.addError(error, stackTrace);
  }

  void update(T Function(T? val) fn) {
    value = fn(value);
  }

  String get string => value.toString();

  @override
  String toString() => value.toString();

  dynamic toJson() => value;

  @override
  bool operator ==(Object other) {
    if (other is T) return value == other;
    if (other is _RxImpl<T>) return value == other.value;
    return false;
  }

  @override
  int get hashCode => value.hashCode;
}

class Rx<T> extends _RxImpl<T> {
  Rx(super.initial);

  Future<void> _lastUpdateFuture = Future.value();

  /// Applies [action] to the current value **sequentially**: calls are queued
  /// and executed strictly in FIFO order, so concurrent async mutations never
  /// interleave.
  ///
  /// ### Error handling
  /// If [action] throws, the queue itself keeps running (later calls are not
  /// blocked) and the error is surfaced as follows:
  ///
  /// 1. It is forwarded to any attached stream consumers (`ever`, `listen`,
  ///    etc.) so Workers can observe it.
  /// 2. If [onError] is provided it is invoked and the returned future
  ///    completes normally.
  /// 3. Otherwise the returned future completes with the error, so an
  ///    `await` propagates it to the caller. A fire-and-forget call that
  ///    fails is reported by the Zone as an unhandled error instead of being
  ///    silently dropped.
  Future<void> updateSequential(
    Future<T> Function(T currentValue) action, {
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    final completer = Completer<void>();
    _lastUpdateFuture = _lastUpdateFuture.then((_) async {
      try {
        final newValue = await action(value);
        value = newValue;
        completer.complete();
      } catch (e, s) {
        notifyStreamError(e, s);
        if (onError != null) {
          onError(e, s);
          completer.complete();
        } else {
          completer.completeError(e, s);
        }
      }
    });
    return completer.future;
  }

  @override
  dynamic toJson() {
    try {
      return (value as dynamic)?.toJson();
    } catch (_) {
      return super.toJson();
    }
  }
}

class Rxn<T> extends Rx<T?> {
  Rxn([super.initial]);

  @override
  dynamic toJson() {
    try {
      return (value as dynamic)?.toJson();
    } catch (_) {
      return super.toJson();
    }
  }
}

class RxInt extends Rx<int> {
  RxInt(super.initial);
}

class RxDouble extends Rx<double> {
  RxDouble(super.initial);
}

class RxString extends Rx<String> {
  RxString(super.initial);
}

class RxBool extends Rx<bool> {
  RxBool(super.initial);
}

class RxnBool extends Rx<bool?> {
  RxnBool([super.initial]);
}

extension RxBoolExt on Rx<bool> {
  bool get isTrue => value;
  bool get isFalse => !value;

  bool operator &(bool other) => other && value;
  bool operator |(bool other) => other || value;
  bool operator ^(bool other) => !other == value;

  void toggle() {
    value = !value;
  }
}

extension RxnBoolExt on Rx<bool?> {
  bool? get isTrue => value;
  bool? get isFalse {
    if (value != null) return !value!;
    return null;
  }

  void toggle() {
    if (value != null) {
      value = !value!;
    }
  }
}
