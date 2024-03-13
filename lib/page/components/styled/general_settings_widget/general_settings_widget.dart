import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/page/components/styled/general_settings_widget/language_tile.dart';
import 'package:linksys_app/page/components/styled/general_settings_widget/theme_tile.dart';
import 'package:linksys_app/providers/app_settings/app_settings_provider.dart';
import 'package:linksys_app/providers/auth/_auth.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/buttons/popup_button.dart';
import 'package:package_info_plus/package_info_plus.dart';

class GeneralSettingsWidget extends ConsumerStatefulWidget {
  const GeneralSettingsWidget({super.key});

  @override
  ConsumerState<GeneralSettingsWidget> createState() =>
      _GeneralSettingsWidgetState();
}

class _GeneralSettingsWidgetState extends ConsumerState<GeneralSettingsWidget> {
  @override
  Widget build(BuildContext context) {
    final loginType =
        ref.watch(authProvider.select((state) => state.value?.loginType)) ??
            LoginType.none;
    final locale =
        ref.watch(appSettingsProvider.select((value) => value.locale));
    return AppPopupButton(
      button: const Icon(
        LinksysIcons.person,
        size: 20,
      ),
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      backgroundColor: Theme.of(context).colorScheme.background,
      builder: (controller) => Container(
        constraints: const BoxConstraints(minWidth: 200, maxWidth: 240),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            LanguageTile(
              locale: locale ?? const Locale('en', 'US'),
              onTap: () {
                controller.close();
                showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return _localeList();
                    });
              },
            ),
            const AppGap.regular(),
            const ThemeTile(),
            const AppGap.regular(),
            ..._displayAdditional(loginType),
            FutureBuilder(
                future:
                    PackageInfo.fromPlatform().then((value) => value.version),
                initialData: '-',
                builder: (context, data) {
                  return AppText.bodySmall(
                    'version ${data.data}',
                  );
                }),
          ],
        ),
      ),
    );
  }

  List<Widget> _displayAdditional(LoginType loginType) {
    if (loginType != LoginType.none) {
      return [
        AppTextButton(
          'Linksys Pledges',
          onTap: () {},
        ),
        AppTextButton(
          'Privacy & Iegal documents',
          onTap: () {},
        ),
        const Divider(
          thickness: 1,
        ),
        const AppText.labelMedium('Router'),
        AppTextButton(
          'Log out',
          onTap: () {
            ref.read(authProvider.notifier).logout();
          },
        ),
        const AppGap.regular(),
      ];
    } else {
      return [];
    }
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
      child: Card(
        child: ListView.builder(
            itemCount: localeList.length,
            itemBuilder: (context, index) {
              final locale = localeList[index];
              return ListTile(
                hoverColor:
                    Theme.of(context).colorScheme.background.withOpacity(.5),
                title: AppText.labelLarge(locale.toString()),
                onTap: () {
                  saveLocale(locale);
                },
              );
            }),
      ),
    );
  }
}
