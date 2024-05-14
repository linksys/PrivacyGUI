import 'package:collection/collection.dart';

const languageData = [
  {'value': 'id', 'name': 'Bahasa Indonesia'},
  {'value': 'da', 'name': 'Dansk'},
  {'value': 'de', 'name': 'Deutsch'},
  {'value': 'en', 'default': true, 'name': 'English (United States)'},
  {'value': 'es-AR', 'name': 'Español (Argentina)'},
  {'value': 'es', 'name': 'Español (España)'},
  {'value': 'fr', 'name': 'Français (France)'},
  {'value': 'fr-CA', 'name': 'Français (Canada)'},
  {'value': 'it', 'name': 'Italiano'},
  {'value': 'nl', 'name': 'Nederlands'},
  {'value': 'nb', 'name': 'Norsk (bokmål)'},
  {'value': 'pl', 'name': 'Polski'},
  {'value': 'pt', 'name': 'Português (Brasil)'},
  {'value': 'pt-PT', 'name': 'Português (Portugal)'},
  {'value': 'fi', 'name': 'Suomi'},
  {'value': 'sv', 'name': 'Svenska'},
  {'value': 'vi', 'name': 'Tiếng Việt Nam'},
  {'value': 'tr', 'name': 'Türkçe'},
  {'value': 'el', 'name': 'Ελληνικά'},
  {'value': 'ru', 'name': 'Русский'},
  {'value': 'ar', 'dir': 'rtl', 'name': 'العربية'},
  {'value': 'th', 'name': 'ไทย'},
  {'value': 'zh', 'name': '简体中文'},
  {'value': 'zh-TW', 'name': '繁體中文'},
  {'value': 'ja', 'name': '日本語'},
  {'value': 'ko', 'name': '한국어'}
];

Map<String, dynamic> getLanguageData(String value) =>
    languageData.firstWhereOrNull((element) => element['value'] == value) ??
    languageData.firstWhere((element) => element['default'] == true);
