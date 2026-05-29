import 'dart:async';
import 'rx_core.dart';

class _Omitted {
  const _Omitted();
}

abstract class _RxImpl<T> extends GetListenable<T> {
  _RxImpl(super.initial);

  T call([dynamic v = const _Omitted()]) {
    if (v is! _Omitted) {
      value = v as T;
    }
    return value;
  }

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

  Future<void> updateSequential(Future<T> Function(T currentValue) action) {
    final completer = Completer<void>();
    _lastUpdateFuture = _lastUpdateFuture.then((_) async {
      try {
        final newValue = await action(value);
        value = newValue;
      } catch (e, s) {
        addError(e, s);
      } finally {
        completer.complete();
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

