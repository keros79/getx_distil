import '../../get.dart';

abstract class Translations {
  Map<String, Map<String, String>> get keys;
}

extension Trans on String {
  String get tr {
    final locale = Get.locale;
    if (locale == null) return this;

    final keyWithCountry = "${locale.languageCode}_${locale.countryCode}";
    final keyLanguageOnly = locale.languageCode;

    if (Get.translations.containsKey(keyWithCountry) &&
        Get.translations[keyWithCountry]!.containsKey(this)) {
      return Get.translations[keyWithCountry]![this]!;
    }

    if (Get.translations.containsKey(keyLanguageOnly) &&
        Get.translations[keyLanguageOnly]!.containsKey(this)) {
      return Get.translations[keyLanguageOnly]![this]!;
    }

    final fallback = Get.fallbackLocale;
    if (fallback != null) {
      final fallbackWithCountry = "${fallback.languageCode}_${fallback.countryCode}";
      final fallbackLanguageOnly = fallback.languageCode;

      if (Get.translations.containsKey(fallbackWithCountry) &&
          Get.translations[fallbackWithCountry]!.containsKey(this)) {
        return Get.translations[fallbackWithCountry]![this]!;
      }

      if (Get.translations.containsKey(fallbackLanguageOnly) &&
          Get.translations[fallbackLanguageOnly]!.containsKey(this)) {
        return Get.translations[fallbackLanguageOnly]![this]!;
      }
    }

    return this;
  }

  String trArgs([List<String> args = const []]) {
    var translated = tr;
    if (args.isNotEmpty) {
      for (final arg in args) {
        translated = translated.replaceFirst(RegExp(r'%s'), arg);
      }
    }
    return translated;
  }

  String trPlural([String? pluralKey, int? i, List<String> args = const []]) {
    return i == 1 ? trArgs(args) : (pluralKey ?? '').trArgs(args);
  }

  String trParams([Map<String, String> params = const {}]) {
    var translated = tr;
    if (params.isNotEmpty) {
      params.forEach((key, value) {
        translated = translated.replaceAll('@$key', value);
      });
    }
    return translated;
  }

  String trPluralParams(
      [String? pluralKey, int? i, Map<String, String> params = const {}]) {
    return i == 1 ? trParams(params) : (pluralKey ?? '').trParams(params);
  }
}
