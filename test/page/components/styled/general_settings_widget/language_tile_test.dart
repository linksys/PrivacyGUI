import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/components/styled/general_settings_widget/language_tile.dart';

/// Lower-case words and digits joined by single hyphens (constitution 11.3).
final _kebabCase = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

// The language list builds each item's identifier on this key (constitution
// 11.3): the locale's tag, never its translated name.
void main() {
  group('localeIdentifierKey', () {
    test('is the language tag in lower case', () {
      expect(
        {
          for (final locale in const [
            Locale('zh', 'TW'),
            Locale('es', 'AR'),
            Locale('en'),
          ])
            locale: localeIdentifierKey(locale),
        },
        {
          const Locale('zh', 'TW'): 'zh-tw',
          const Locale('es', 'AR'): 'es-ar',
          const Locale('en'): 'en',
        },
      );
    });

    test('is kebab case and different for every supported locale', () {
      final keys =
          AppLocalizations.supportedLocales.map(localeIdentifierKey).toList();

      expect(keys, everyElement(matches(_kebabCase)));
      expect(keys.toSet(), hasLength(keys.length));
    });
  });
}
