import 'package:flutter/material.dart';
import '../rx/rx_types.dart';
import '../rx/rx_extensions.dart';
import '../state_manager/getx_controller.dart';
import 'binding_widget.dart';

class _Dependency {
  final Object? Function()? factory;
  Object? instance;
  final bool permanent;
  final bool fenix;

  _Dependency({
    this.factory,
    this.instance,
    this.permanent = false,
    this.fenix = false,
  });

  bool get isInstantiated => instance != null;
}

class Get {
  Get._();

  static final Rxn<Locale> _locale = Rxn<Locale>();
  static Locale? get locale => _locale.value;
  static set locale(Locale? val) => _locale.value = val;

  static Listenable get localeListenable => _locale;

  static final Rxn<Locale> _fallbackLocale = Rxn<Locale>();
  static Locale? get fallbackLocale => _fallbackLocale.value;
  static set fallbackLocale(Locale? val) => _fallbackLocale.value = val;

  static final Rx<ThemeMode> _themeMode = ThemeMode.system.obs;
  static ThemeMode get themeMode => _themeMode.value;
  static set themeMode(ThemeMode val) => _themeMode.value = val;

  static final Rxn<ThemeData> _theme = Rxn<ThemeData>();
  static ThemeData? get theme => _theme.value;
  static set theme(ThemeData? val) => _theme.value = val;

  static final Rxn<ThemeData> _darkTheme = Rxn<ThemeData>();
  static ThemeData? get darkTheme => _darkTheme.value;
  static set darkTheme(ThemeData? val) => _darkTheme.value = val;

  static final Map<String, Map<String, String>> translations = {};

  static void addTranslations(Map<String, Map<String, String>> tr) {
    translations.addAll(tr);
  }

  static void clearTranslations() {
    translations.clear();
  }

  // Global registry for Hybrid DI
  static final Map<String, _Dependency> _globalRegistry = {};

  static String _getKey(Type type, String? tag) {
    return tag == null ? type.toString() : '${type.toString()}#$tag';
  }

  /// Checks if a dependency of type [T] is registered in the global registry
  /// (instantiated **or** lazily prepared).
  static bool isRegistered<T>({String? tag}) {
    return _globalRegistry.containsKey(_getKey(T, tag));
  }

  /// Checks if a dependency of type [T] is registered lazily and has **not**
  /// been instantiated yet (a pending `lazyPut`, or a `fenix` dependency that
  /// was deleted and is waiting to be rebuilt).
  static bool isPrepared<T>({String? tag}) {
    final dep = _globalRegistry[_getKey(T, tag)];
    return dep != null && !dep.isInstantiated && dep.factory != null;
  }

  /// Registers a global dependency instantly.
  ///
  /// * If a **live** instance is already registered under the same key, it is
  ///   returned unchanged to preserve singleton behaviour ([dependency] is
  ///   discarded).
  /// * If the key only holds a pending lazy/fenix factory, [dependency]
  ///   replaces it — the provided instance is used, not the old factory.
  static T put<T>(T dependency, {String? tag, bool permanent = false}) {
    final key = _getKey(T, tag);
    final existing = _globalRegistry[key];
    if (existing != null && existing.isInstantiated) {
      return existing.instance as T;
    }

    _globalRegistry[key] = _Dependency(
      instance: dependency,
      permanent: permanent,
      fenix: existing?.fenix ?? false,
      factory: existing?.factory,
    );
    if (dependency is GetLifeCycleMixin) {
      dependency.onStart();
    }
    return dependency;
  }

  /// Registers a global dependency lazily. It will be instantiated on the
  /// first [find] call.
  ///
  /// With [fenix] `true`, the dependency survives [delete]: the instance is
  /// disposed (`onClose` runs) but the builder stays registered, so the next
  /// [find] transparently creates a fresh instance — like a phoenix.
  static void lazyPut<T>(
    T Function() builder, {
    String? tag,
    bool fenix = false,
  }) {
    final key = _getKey(T, tag);
    _globalRegistry[key] = _Dependency(factory: builder, fenix: fenix);
  }

  /// Deletes a registered dependency from the global registry, invoking
  /// `onClose` if applicable.
  ///
  /// * `permanent` dependencies are only removed when [force] is `true`.
  /// * `fenix` dependencies are disposed but their builder is kept, so
  ///   [isRegistered] stays `true` and the next [find] rebuilds them. Use
  ///   [reset] to drop fenix builders entirely.
  ///
  /// Returns `true` when an instance was disposed or a registration removed.
  static bool delete<T>({String? tag, bool force = false}) {
    final key = _getKey(T, tag);
    final dep = _globalRegistry[key];
    if (dep == null) return false;
    if (dep.permanent && !force) return false;

    final instance = dep.instance;
    if (instance is GetLifeCycleMixin) {
      instance.onDelete();
    }

    if (dep.fenix && dep.factory != null) {
      // Re-arm: keep the builder, drop the instance.
      _globalRegistry[key] = _Dependency(factory: dep.factory, fenix: true);
    } else {
      _globalRegistry.remove(key);
    }
    return true;
  }

  /// Clears all non-permanent dependencies from the global registry and
  /// resets theme state.
  ///
  /// With [clearFactory] `false`, lazy/fenix **builders** are kept (their
  /// instances are still disposed), so a subsequent [find] re-creates them.
  static void reset({bool clearFactory = true}) {
    final keysToRemove = <String>[];
    _globalRegistry.forEach((key, dep) {
      if (dep.permanent) return;
      final instance = dep.instance;
      if (instance is GetLifeCycleMixin) {
        instance.onDelete();
      }
      if (!clearFactory && dep.factory != null) {
        dep.instance = null; // keep the builder, drop the instance
      } else {
        keysToRemove.add(key);
      }
    });
    for (final key in keysToRemove) {
      _globalRegistry.remove(key);
    }
    BindingWidgetState.clearImmortal();
    _themeMode.value = ThemeMode.system;
    _theme.value = null;
    _darkTheme.value = null;
  }

  /// Instantiates a lazily registered dependency if needed and returns it.
  static T? _resolveGlobal<T>(String key) {
    final dep = _globalRegistry[key];
    if (dep == null) return null;
    if (!dep.isInstantiated && dep.factory != null) {
      final instance = dep.factory!();
      dep.instance = instance;
      if (instance is GetLifeCycleMixin) {
        instance.onStart();
      }
    }
    return dep.instance as T?;
  }

  /// Finds the registered instance of type [T].
  ///
  /// ```dart
  /// Get.find<CartController>();                    // context-less
  /// Get.find<CartController>(context: context);    // widget-tree scoped first
  /// Get.find<CartController>(tag: 'wishlist');     // global registry, tagged (GetX-style)
  /// ```
  ///
  /// Resolution order when [context] is provided and no [tag] is given:
  /// 1. Immortal `GetxService`s created by any `BindingWidget` scope.
  /// 2. The nearest ancestor `BindingWidget` declaring `T`.
  /// 3. The global registry (`put` / `lazyPut`).
  /// 4. Live scoped instances reachable without a context (weak registry).
  ///
  /// Without a [context] the global registry is consulted first, then
  /// immortals, then live scoped instances.
  ///
  /// [tag] is a **global-registry-only** concept (`Get.put(tag:)`). Scoped DI
  /// is identified by type + widget-tree position, so a tagged lookup goes
  /// straight to the global registry and skips every scoped step.
  static T find<T>({BuildContext? context, String? tag}) {
    // Tags never apply to scoped DI: resolve from the global registry only.
    if (tag != null) {
      final tagged = _resolveGlobal<T>(_getKey(T, tag));
      if (tagged != null) return tagged;
      throw _notFound<T>(context, tag);
    }

    // 1. Widget tree-scoped lookup (context provided)
    if (context != null) {
      final immortal = BindingWidgetState.getImmortal<T>();
      if (immortal != null) {
        return immortal;
      }

      InheritedBinding? foundBinding;
      InheritedElement? foundElement;

      context.visitAncestorElements((element) {
        if (element is InheritedElement && element.widget is InheritedBinding) {
          final binding = element.widget as InheritedBinding;
          if (binding.state.hasBinding<T>()) {
            foundBinding = binding;
            foundElement = element;
            return false; // Stop traversal
          }
        }
        return true; // Continue traversal
      });

      if (foundElement != null && foundBinding != null) {
        context.dependOnInheritedElement(foundElement!);
        return foundBinding!.state.getInstance<T>();
      }
    }

    // 2. Global registry lookup (lazy instantiation)
    final global = _resolveGlobal<T>(_getKey(T, null));
    if (global != null) {
      return global;
    }

    // 3. Global immortal instance lookup (context-less path)
    final immortal = BindingWidgetState.getImmortal<T>();
    if (immortal != null) {
      return immortal;
    }

    // 4. Live scoped instances / active scopes (context-less fallback)
    final weakInstance = BindingWidgetState.getWeak<T>();
    if (weakInstance != null) {
      return weakInstance;
    }

    throw _notFound<T>(context, null);
  }

  static FlutterError _notFound<T>(BuildContext? context, String? tag) {

    final String contextWidgetName = context != null
        ? context.widget.runtimeType.toString()
        : 'Unknown';
    final List<String> ancestors = [];
    if (context != null) {
      context.visitAncestorElements((element) {
        ancestors.add(element.widget.runtimeType.toString());
        return true;
      });
    }
    final String searchPath = ancestors.isNotEmpty
        ? ancestors.join(' -> ')
        : 'N/A';
    final List<String> globalKeys = _globalRegistry.keys.toList();
    final List<Type> immortalKeys = BindingWidgetState.getImmortalKeys();

    return FlutterError(
      'Could not find any instance of type $T${tag != null ? ' with tag "$tag"' : ''} in either Widget Tree or Global Registry.\n\n'
      '📍 Requested Context Widget: $contextWidgetName\n'
      '🌳 Search Path (Ancestor Widgets):\n'
      '   $contextWidgetName -> $searchPath\n\n'
      '🌐 Registered Global Services:\n'
      '   ${globalKeys.isEmpty ? 'None' : globalKeys.join(', ')}\n\n'
      '🌟 Registered Immortal Services:\n'
      '   ${immortalKeys.isEmpty ? 'None' : immortalKeys.join(', ')}\n\n'
      'Make sure you registered it via Get.put() / Get.lazyPut() or wrapped your view with a BindingWidget.',
    );
  }
}
