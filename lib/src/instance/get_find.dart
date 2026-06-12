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

  /// Checks if a dependency of type [T] is registered in the global registry.
  static bool isRegistered<T>({String? tag}) {
    final key = _getKey(T, tag);
    return _globalRegistry.containsKey(key);
  }

  /// Registers a global dependency instantly.
  /// If it is already registered, it returns the existing instance to preserve singleton behavior.
  static T put<T>(T dependency, {String? tag, bool permanent = false}) {
    final key = _getKey(T, tag);
    if (_globalRegistry.containsKey(key)) {
      final dep = _globalRegistry[key]!;
      if (dep.instance == null && dep.factory != null) {
        final instance = dep.factory!();
        dep.instance = instance;
        if (instance is GetLifeCycleMixin) {
          instance.onStart();
        }
      }
      if (dep.instance != null) {
        return dep.instance as T;
      }
    }

    _globalRegistry[key] = _Dependency(
      instance: dependency,
      permanent: permanent,
    );
    if (dependency is GetLifeCycleMixin) {
      dependency.onStart();
    }
    return dependency;
  }

  /// Registers a global dependency lazily. It will be instantiated on the first [find] call.
  static void lazyPut<T>(T Function() builder, {String? tag, bool fenix = false}) {
    final key = _getKey(T, tag);
    _globalRegistry[key] = _Dependency(
      factory: builder,
      fenix: fenix,
    );
  }

  /// Deletes a registered dependency from the global registry, invoking onClose if applicable.
  static bool delete<T>({String? tag, bool force = false}) {
    final key = _getKey(T, tag);
    if (_globalRegistry.containsKey(key)) {
      final dep = _globalRegistry[key]!;
      if (!dep.permanent || force) {
        if (dep.instance is GetLifeCycleMixin) {
          (dep.instance as GetLifeCycleMixin).onDelete();
        }
        _globalRegistry.remove(key);
        return true;
      }
    }
    return false;
  }

  /// Clears all non-permanent dependencies from the global registry.
  static void reset({bool clearFactory = true}) {
    final keysToRemove = <String>[];
    _globalRegistry.forEach((key, dep) {
      if (!dep.permanent) {
        if (dep.instance is GetLifeCycleMixin) {
          (dep.instance as GetLifeCycleMixin).onDelete();
        }
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

  /// Finds the registered instance of type [T].
  ///
  /// Priority:
  /// 1. Widget tree-scoped DI (if [context] is provided and [tag] is null).
  /// 2. Global registry (for instances registered via [put] or [lazyPut]).
  /// 3. Global immortal instances (for [GetxService]s instantiated via widget-scoped DI).
  static T find<T>([BuildContext? context, String? tag]) {
    // 1. Widget tree-scoped lookup (if context is provided and tag is null)
    if (context != null && tag == null) {
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

    // 2. Global registry lookup (supports tags and lazy instantiation)
    final key = _getKey(T, tag);
    if (_globalRegistry.containsKey(key)) {
      final dep = _globalRegistry[key]!;
      if (dep.instance == null && dep.factory != null) {
        final instance = dep.factory!();
        dep.instance = instance;
        if (instance is GetLifeCycleMixin) {
          instance.onStart();
        }
      }
      if (dep.instance != null) {
        return dep.instance as T;
      }
    }

    // 3. Global immortal instance lookup (if context is null but tag is null)
    if (tag == null) {
      final immortal = BindingWidgetState.getImmortal<T>();
      if (immortal != null) {
        return immortal;
      }
    }

    // 4. Global weak registry lookup (fallback for scoped controllers when context is null)
    if (tag == null) {
      final weakInstance = BindingWidgetState.getWeak<T>();
      if (weakInstance != null) {
        return weakInstance;
      }
    }

    final String contextWidgetName = context != null ? context.widget.runtimeType.toString() : 'Unknown';
    final List<String> ancestors = [];
    if (context != null) {
      context.visitAncestorElements((element) {
        ancestors.add(element.widget.runtimeType.toString());
        return true;
      });
    }
    final String searchPath = ancestors.isNotEmpty ? ancestors.join(' -> ') : 'N/A';
    final List<String> globalKeys = _globalRegistry.keys.toList();
    final List<Type> immortalKeys = BindingWidgetState.getImmortalKeys();

    throw FlutterError(
      'Could not find any instance of type $T${tag != null ? ' with tag "$tag"' : ''} in either Widget Tree or Global Registry.\n\n'
      '📍 Requested Context Widget: $contextWidgetName\n'
      '🌳 Search Path (Ancestor Widgets):\n'
      '   $contextWidgetName -> $searchPath\n\n'
      '🌐 Registered Global Services:\n'
      '   ${globalKeys.isEmpty ? 'None' : globalKeys.join(', ')}\n\n'
      '🌟 Registered Immortal Services:\n'
      '   ${immortalKeys.isEmpty ? 'None' : immortalKeys.join(', ')}\n\n'
      'Make sure you registered it via Get.put() / Get.lazyPut() or wrapped your view with a BindingWidget.'
    );
  }
}

