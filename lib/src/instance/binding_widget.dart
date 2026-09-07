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

  /// Types that already produced an ambiguity warning (debug only), so the log
  /// is not flooded on every lookup.
  static final Set<Type> _warnedAmbiguous = {};

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
      _instantiate(bind);
    }
  }

  /// Instantiates [bind] inside this scope (or returns the existing instance).
  Object _instantiate(Bind<dynamic> bind) {
    final type = bind.type;
    final existing = _immortalInstances[type] ?? _instances[type];
    if (existing != null) return existing;

    final instance = bind.factory() as Object;
    if (instance is GetxService) {
      _immortalInstances[type] = instance;
    } else {
      _instances[type] = instance;
      _registerWeak(type, instance);
    }

    if (instance is GetLifeCycleMixin) {
      instance.onStart();
    }
    return instance;
  }

  // ─── Context-less lookup ───────────────────────────────────────────────────

  /// Resolves an already-instantiated scoped instance of [T] without a
  /// `BuildContext`.
  ///
  /// Resolution order:
  /// 1. **Live instances** in the weak registry. When more than one scope
  ///    currently holds an instance of [T], the most recently created one wins
  ///    and a one-time debug warning is printed — pass a `BuildContext` to
  ///    resolve the correct scope deterministically.
  /// 2. **Declared but not yet instantiated** bindings in active scopes — see
  ///    [findOrInitializeInActiveStates].
  static T? getWeak<T>() {
    final list = _weakRegistry[T];
    if (list != null && list.isNotEmpty) {
      list.removeWhere((ref) => ref.target == null);
      if (list.length > 1) _warnAmbiguous(T, list.length, live: true);
      if (list.isNotEmpty) {
        return list.last.target as T?;
      }
    }
    return findOrInitializeInActiveStates<T>();
  }

  /// Falls back to active [BindingWidget] scopes that *declare* [T] but have
  /// not created it yet, and instantiates it there.
  ///
  /// Instantiation is a side effect, so it is only reached when **no live
  /// instance** exists. If several active scopes declare [T], the most
  /// recently mounted scope is used and a one-time debug warning is printed.
  /// Prefer a `BuildContext` in that situation.
  static T? findOrInitializeInActiveStates<T>() {
    BindingWidgetState? target;
    var declaringScopes = 0;
    for (final state in _activeStates.reversed) {
      if (state.hasBinding<T>()) {
        target ??= state;
        declaringScopes++;
      }
    }
    if (target == null) return null;
    if (declaringScopes > 1) _warnAmbiguous(T, declaringScopes, live: false);
    return target.getInstance<T>();
  }

  static void _warnAmbiguous(Type type, int count, {required bool live}) {
    assert(() {
      if (_warnedAmbiguous.add(type)) {
        final what = live
            ? 'live scoped instances'
            : 'active BindingWidget scopes declaring it';
        debugPrint(
          '[getx_distil] Ambiguous context-less Get.find<$type>(): '
          '$count $what were found. The most recent one is returned'
          '${live ? '' : ' and instantiated there'}. '
          'Pass a BuildContext (Get.find<$type>(context: context)) so the '
          'widget tree decides which scope you mean.',
        );
      }
      return true;
    }());
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
    return _immortalInstances[T] as T?;
  }

  static void clearImmortal() {
    _immortalInstances.clear();
  }

  static List<Type> getImmortalKeys() {
    return _immortalInstances.keys.toList();
  }

  /// Number of live scoped instances currently registered for [T].
  /// Exposed for diagnostics and tests.
  @visibleForTesting
  static int liveInstanceCount<T>() {
    final list = _weakRegistry[T];
    if (list == null) return 0;
    list.removeWhere((ref) => ref.target == null);
    return list.length;
  }

  @visibleForTesting
  static void resetAmbiguityWarnings() => _warnedAmbiguous.clear();

  // ─── Scope API ─────────────────────────────────────────────────────────────

  bool hasBinding<T>() {
    return _immortalInstances.containsKey(T) ||
        widget.bindings.any((b) => b.type == T);
  }

  T getInstance<T>() {
    final immortal = _immortalInstances[T];
    if (immortal != null) return immortal as T;
    final local = _instances[T];
    if (local != null) return local as T;

    final bind = widget.bindings.firstWhere(
      (b) => b.type == T,
      orElse: () => throw FlutterError('Binding not found for type $T'),
    );

    return _instantiate(bind) as T;
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
