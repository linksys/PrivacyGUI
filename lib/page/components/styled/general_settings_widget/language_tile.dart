import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/util/extensions.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';

class LanguageTile extends ConsumerStatefulWidget {
  final void Function(Locale locale)? onSelected;
  final void Function()? onTap;
  final Locale locale;
  final IconData icon;
  final bool showAbbr;

  const LanguageTile({
    super.key,
    this.onSelected,
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
        ).then((locale) {
          if (locale == null) {
            return;
          }
          widget.onSelected?.call(locale);
        });
        widget.onTap?.call();
      },
      child: Semantics(
          identifier: 'now-general-settings-locale',
          label: 'locale',
          child: _displayLocale(widget.locale)),
    );
  }

  Widget _displayLocale(Locale locale) {
    return widget.showAbbr
        ? AppText.labelLarge(locale.languageCode.toUpperCase())
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon),
              const AppGap.medium(),
              Flexible(child: AppText.labelMedium(locale.displayText)),
            ],
          );
  }

  // NEED TO revisit
  Widget _localeList() {
    const localeList = AppLocalizations.supportedLocales;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Semantics(
        identifier: 'now-locale-list',
        label: 'locale list',
        explicitChildNodes: true,
        child: ListView.builder(
            itemCount: localeList.length,
            itemBuilder: (context, index) {
              final locale = localeList[index];
              return ListTile(
                hoverColor:
                    Theme.of(context).colorScheme.background.withOpacity(.5),
                title: Semantics(
                    identifier: 'now-locale-item-${locale.toLanguageTag()}',
                    child: AppText.labelLarge(locale.displayText)),
                trailing: widget.locale == locale
                    ? Semantics(
                        identifier: 'now-locale-item-checked',
                        label: 'checked',
                        child: const Icon(LinksysIcons.check))
                    : null,
                onTap: () {
                  context.pop(locale);
                },
              );
            }),
      ),
    );
  }
}
