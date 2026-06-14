import 'package:flutter/widgets.dart';
import 'bind.dart';
import '../state_manager/getx_controller.dart';

class InheritedBinding extends InheritedWidget {
  final BindingWidgetState state;

  const InheritedBinding({
    super.key,
    required this.state,
    required super.child,
  });

  @override
  bool updateShouldNotify(InheritedBinding oldWidget) => false;
}

class BindingWidget extends StatefulWidget {
  final List<Bind<dynamic>> bindings;
  final Widget child;
  final bool eager;

  const BindingWidget({
    super.key,
    required this.bindings,
    required this.child,
    this.eager = false,
  });

  @override
  State<BindingWidget> createState() => BindingWidgetState();
}

class BindingWidgetState extends State<BindingWidget> {
  final Map<Type, Object> _instances = {};
  static final Map<Type, Object> _immortalInstances = {};

  static final List<BindingWidgetState> _activeStates = [];
  static final Map<Type, List<WeakReference<Object>>> _weakRegistry = {};

  @override
  void initState() {
    super.initState();
    _activeStates.add(this);
    if (widget.eager) {
      _initializeEagerBindings();
    }
  }

  void _initializeEagerBindings() {
    for (final bind in widget.bindings) {
      final type = bind.type;
      if (_immortalInstances.containsKey(type) || _instances.containsKey(type)) {
        continue;
      }
      final instance = bind.factory();
      if (instance is GetxService) {
        _immortalInstances[type] = instance;
      } else {
        _instances[type] = instance;
        _registerWeak(type, instance);
      }

      if (instance is GetLifeCycleMixin) {
        instance.onStart();
      }
    }
  }

  static T? getWeak<T>() {
    final list = _weakRegistry[T];
    if (list != null && list.isNotEmpty) {
      list.removeWhere((ref) => ref.target == null);
      if (list.isNotEmpty) {
        return list.last.target as T?;
      }
    }
    return findOrInitializeInActiveStates<T>();
  }

  static T? findOrInitializeInActiveStates<T>() {
    for (final state in _activeStates.reversed) {
      if (state.hasBinding<T>()) {
        return state.getInstance<T>();
      }
    }
    return null;
  }

  static void _registerWeak(Type type, Object instance) {
    _weakRegistry.putIfAbsent(type, () => []).add(WeakReference(instance));
  }

  static void _unregisterWeak(Type type, Object instance) {
    final list = _weakRegistry[type];
    if (list != null) {
      list.removeWhere((ref) => ref.target == null || ref.target == instance);
      if (list.isEmpty) {
        _weakRegistry.remove(type);
      }
    }
  }

  static T? getImmortal<T>() {
    if (_immortalInstances.containsKey(T)) {
      return _immortalInstances[T] as T?;
    }
    return null;
  }

  static void clearImmortal() {
    _immortalInstances.clear();
  }

  static List<Type> getImmortalKeys() {
    return _immortalInstances.keys.toList();
  }

  bool hasBinding<T>() {
    return _immortalInstances.containsKey(T) || widget.bindings.any((b) => b.type == T);
  }

  T getInstance<T>() {
    if (_immortalInstances.containsKey(T)) {
      return _immortalInstances[T] as T;
    }
    if (_instances.containsKey(T)) {
      return _instances[T] as T;
    }

    final bind = widget.bindings.firstWhere(
      (b) => b.type == T,
      orElse: () => throw FlutterError('Binding not found for type $T'),
    );

    final instance = bind.factory();
    if (instance is GetxService) {
      _immortalInstances[T] = instance;
    } else {
      _instances[T] = instance;
      _registerWeak(T, instance);
    }

    if (instance is GetLifeCycleMixin) {
      instance.onStart();
    }

    return instance as T;
  }

  @override
  void dispose() {
    _activeStates.remove(this);
    // Run onDelete() on all instances first while they are still accessible in the weak registry
    for (final instance in _instances.values) {
      if (instance is GetLifeCycleMixin && instance is! GetxService) {
        instance.onDelete();
      }
    }
    // Batch remove from local instances map and weak registry
    _instances.forEach((type, instance) {
      _unregisterWeak(type, instance);
    });
    _instances.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InheritedBinding(
      state: this,
      child: widget.child,
    );
  }
}
