import 'package:flutter/widgets.dart';
import '../rx/rx_types.dart';
import 'binding_widget.dart';

class Get {
  Get._();

  static final Rxn<Locale> _locale = Rxn<Locale>();
  static Locale? get locale => _locale.value;
  static set locale(Locale? val) => _locale.value = val;

  static final Rxn<Locale> _fallbackLocale = Rxn<Locale>();
  static Locale? get fallbackLocale => _fallbackLocale.value;
  static set fallbackLocale(Locale? val) => _fallbackLocale.value = val;

  static final Map<String, Map<String, String>> translations = {};

  static void addTranslations(Map<String, Map<String, String>> tr) {
    translations.addAll(tr);
  }

  static void clearTranslations() {
    translations.clear();
  }

  static T find<T>(BuildContext context) {
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

    throw FlutterError(
      'Could not find any BindingWidget containing the type $T in the widget tree. '
      'Make sure you wrapped your view with a BindingWidget containing Bind<$T>(...).'
    );
  }
}
