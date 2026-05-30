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

  const BindingWidget({
    super.key,
    required this.bindings,
    required this.child,
  });

  @override
  State<BindingWidget> createState() => BindingWidgetState();
}

class BindingWidgetState extends State<BindingWidget> {
  final Map<Type, Object> _instances = {};
  static final Map<Type, Object> _immortalInstances = {};

  static T? getImmortal<T>() {
    if (_immortalInstances.containsKey(T)) {
      return _immortalInstances[T] as T?;
    }
    return null;
  }

  static void clearImmortal() {
    _immortalInstances.clear();
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
    }

    if (instance is GetLifeCycleMixin) {
      instance.onStart();
    }

    return instance as T;
  }

  @override
  void dispose() {
    for (final instance in _instances.values) {
      if (instance is GetLifeCycleMixin) {
        if (instance is GetxService) continue;
        instance.onDelete();
      }
    }
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
