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
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activeLocale = Get.locale;
      if (routerConfig != null) {
        return MaterialApp.router(
          key: widgetKey,
          routerConfig: routerConfig,
          theme: theme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          locale: activeLocale,
          localizationsDelegates: localizationsDelegates,
          supportedLocales: supportedLocales ?? const <Locale>[Locale('en', 'US')],
          builder: builder,
        );
      } else {
        return MaterialApp(
          key: widgetKey,
          home: home,
          theme: theme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          locale: activeLocale,
          localizationsDelegates: localizationsDelegates,
          supportedLocales: supportedLocales ?? const <Locale>[Locale('en', 'US')],
          builder: builder,
        );
      }
    });
  }
}
