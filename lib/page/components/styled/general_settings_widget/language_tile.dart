import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/page/components/shortcuts/dialogs.dart';
import 'package:linksys_app/providers/app_settings/app_settings_provider.dart';
import 'package:linksys_app/util/extensions.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LanguageTile extends ConsumerStatefulWidget {
  final void Function()? onTap;
  final Locale locale;
  final IconData icon;
  final bool showAbbr;

  const LanguageTile({
    super.key,
    this.onTap,
    required this.locale,
    this.icon = LinksysIcons.language,
    this.showAbbr = false,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LanguageTileState();
}

class _LanguageTileState extends ConsumerState<LanguageTile> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showSimpleAppDialog(
          context,
          content: _localeList(),
        );
        widget.onTap?.call();
      },
      child: _displayLocale(widget.locale),
    );
  }

  Widget _displayLocale(Locale locale) {
    return widget.showAbbr
        ? AppText.labelLarge(locale.languageCode.toUpperCase())
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon),
              const AppGap.regular(),
              Flexible(child: AppText.labelMedium(locale.displayText)),
            ],
          );
  }

  // NEED TO revisit
  Widget _localeList() {
    const localeList = AppLocalizations.supportedLocales;
    saveLocale(Locale locale) {
      final appSettings = ref.read(appSettingsProvider);

      ref.read(appSettingsProvider.notifier).state =
          appSettings.copyWith(locale: locale);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ListView.builder(
          itemCount: localeList.length,
          itemBuilder: (context, index) {
            final locale = localeList[index];
            return ListTile(
              hoverColor:
                  Theme.of(context).colorScheme.background.withOpacity(.5),
              title: AppText.labelLarge(locale.displayText),
              onTap: () {
                saveLocale(locale);
                context.pop();
              },
            );
          }),
    );
  }
}
