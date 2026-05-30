import 'package:flutter/material.dart';
import '../../get.dart';

class GetMaterialApp extends StatelessWidget {
  final Widget? home;
  final ThemeData? theme;
  final ThemeData? darkTheme;
  final ThemeMode? themeMode;
  final Translations? translations;
  final Locale? locale;
  final Locale? fallbackLocale;
  final RouterConfig<Object>? routerConfig;
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final Iterable<Locale>? supportedLocales;
  final Widget Function(BuildContext, Widget?)? builder;
  final Key? widgetKey;
  final List<Bind<dynamic>>? bindings;

  GetMaterialApp({
    super.key,
    this.home,
    this.theme,
    this.darkTheme,
    this.themeMode,
    this.translations,
    this.locale,
    this.fallbackLocale,
    this.routerConfig,
    this.localizationsDelegates,
    this.supportedLocales,
    this.builder,
    this.widgetKey,
    this.bindings,
  }) {
    if (translations != null) {
      Get.addTranslations(translations!.keys);
    }
    if (locale != null && Get.locale == null) {
      Get.locale = locale;
    }
    if (fallbackLocale != null && Get.fallbackLocale == null) {
      Get.fallbackLocale = fallbackLocale;
    }
    if (theme != null && Get.theme == null) {
      Get.theme = theme;
    }
    if (darkTheme != null && Get.darkTheme == null) {
      Get.darkTheme = darkTheme;
    }
    if (themeMode != null) {
      Get.themeMode = themeMode!;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget app = Obx(() {
      final activeLocale = Get.locale;
      final activeTheme = Get.theme ?? theme;
      final activeDarkTheme = Get.darkTheme ?? darkTheme;
      final activeThemeMode = Get.themeMode;

      if (routerConfig != null) {
        return MaterialApp.router(
          key: widgetKey,
          routerConfig: routerConfig,
          theme: activeTheme,
          darkTheme: activeDarkTheme,
          themeMode: activeThemeMode,
          locale: activeLocale,
          localizationsDelegates: localizationsDelegates,
          supportedLocales: supportedLocales ?? const <Locale>[Locale('en', 'US')],
          builder: builder,
        );
      } else {
        return MaterialApp(
          key: widgetKey,
          home: home,
          theme: activeTheme,
          darkTheme: activeDarkTheme,
          themeMode: activeThemeMode,
          locale: activeLocale,
          localizationsDelegates: localizationsDelegates,
          supportedLocales: supportedLocales ?? const <Locale>[Locale('en', 'US')],
          builder: builder,
        );
      }
    });

    if (bindings != null && bindings!.isNotEmpty) {
      app = BindingWidget(
        bindings: bindings!,
        child: app,
      );
    }

    return app;
  }
}
