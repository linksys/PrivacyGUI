import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/util/extensions.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:ui_kit_library/ui_kit.dart';

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
    this.icon = AppFontIcons.language,
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
              AppGap.lg(),
              Flexible(child: AppText.labelMedium(locale.displayText)),
            ],
          );
  }

  // NEED TO revisit
  Widget _localeList() {
    const localeList = AppLocalizations.supportedLocales;
    // Calculate height based on number of items (56px per ListTile, capped at 400px)
    final listHeight = (localeList.length * 56.0).clamp(100.0, 400.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Semantics(
        identifier: 'now-locale-list',
        label: 'locale list',
        explicitChildNodes: true,
        child: SizedBox(
          height: listHeight,
          child: ListView.builder(
              itemCount: localeList.length,
              itemBuilder: (context, index) {
                final locale = localeList[index];
                final isSelected = widget.locale == locale;
                return AppListTile(
                  key: Key('locale_item_${locale.toLanguageTag()}'),
                  selected: isSelected,
                  title: Semantics(
                      identifier: 'now-locale-item-${locale.toLanguageTag()}',
                      child: AppText.labelLarge(locale.displayText)),
                  trailing: isSelected
                      ? Semantics(
                          identifier: 'now-locale-item-checked',
                          label: 'checked',
                          child: const AppIcon.font(AppFontIcons.check))
                      : null,
                  onTap: () {
                    context.pop(locale);
                  },
                );
              }),
        ),
      ),
    );
  }
}
