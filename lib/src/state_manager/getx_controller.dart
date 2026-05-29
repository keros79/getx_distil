import 'package:flutter/widgets.dart';

mixin GetLifeCycleMixin {
  bool _initialized = false;
  bool get initialized => _initialized;

  bool _isClosed = false;
  bool get isClosed => _isClosed;

  @mustCallSuper
  void onInit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isClosed) {
        onReady();
      }
    });
  }

  void onReady() {}

  void onClose() {}

  @mustCallSuper
  void onStart() {
    if (_initialized) return;
    onInit();
    _initialized = true;
  }

  @mustCallSuper
  void onDelete() {
    if (_isClosed) return;
    _isClosed = true;
    onClose();
  }
}

abstract class GetxController with GetLifeCycleMixin {
  final List<VoidCallback> _updaters = [];

  void update([List<Object>? ids, bool condition = true]) {
    if (!condition) return;
    final list = List<VoidCallback>.from(_updaters);
    for (final updater in list) {
      updater();
    }
  }

  VoidCallback addListener(VoidCallback listener) {
    _updaters.add(listener);
    return () => _updaters.remove(listener);
  }

  void removeListener(VoidCallback listener) {
    _updaters.remove(listener);
  }

  @override
  @mustCallSuper
  void onClose() {
    _updaters.clear();
  }
}

abstract class GetxService with GetLifeCycleMixin {}
