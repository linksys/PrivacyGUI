import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/constants/url_links.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/general_settings_widget/language_tile.dart';
import 'package:privacy_gui/page/components/styled/general_settings_widget/theme_tile.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/buttons/popup_button.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

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

    return AppPopupButton(
      parent: shellNavigatorKey.currentContext,
      button: Semantics(
        identifier: 'now-topbar-icon-general-settings',
        label: 'general settings',
        child: const Icon(
          LinksysIcons.person,
          size: 20,
        ),
      ),
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      backgroundColor: Theme.of(context).colorScheme.background,
      builder: (controller) {
        final locale =
            ref.watch(appSettingsProvider.select((value) => value.locale));
        return Semantics(
          explicitChildNodes: true,
          child: Container(
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 240),
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: LanguageTile(
                    locale: locale ?? const Locale('en'),
                    onTap: () {
                      controller.close();
                    },
                    onSelected: (locale) {
                      final appSettings = ref.read(appSettingsProvider);

                      ref
                          .read(appSettingsProvider.notifier)
                          .update(appSettings.copyWith(locale: locale));
                    },
                  ),
                ),
                const AppGap.medium(),
                Padding(
                  padding: const EdgeInsets.all(Spacing.small2),
                  child: Semantics(
                    identifier: 'now-general-settings-theme',
                    label: 'theme',
                    child: const ThemeTile(),
                  ),
                ),
                const AppGap.medium(),
                ..._displayAdditional(loginType),
                FutureBuilder(
                    future: getVersion(full: true),
                    initialData: '-',
                    builder: (context, data) {
                      return Semantics(
                        identifier: 'now-general-text-version',
                        label: 'version',
                        child: AppText.bodySmall(
                          'version ${data.data}',
                        ),
                      );
                    }),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _displayAdditional(LoginType loginType) {
    if (loginType != LoginType.none) {
      return [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: AppTextButton(
            loc(context).endUserLicenseAgreement,
            onTap: () {
              gotoOfficialWebUrl(linkEULA,
                  locale: ref.read(appSettingsProvider).locale);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: AppTextButton(
            loc(context).termsOfService,
            onTap: () {
              gotoOfficialWebUrl(linkTerms,
                  locale: ref.read(appSettingsProvider).locale);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: AppTextButton(
            loc(context).thirdPartyLicenses,
            onTap: () {
              gotoOfficialWebUrl(linkThirdParty,
                  locale: ref.read(appSettingsProvider).locale);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: AppTextButton(
            loc(context).privacyAndSecurity,
            onTap: () {
              gotoOfficialWebUrl(linkPrivacy,
                  locale: ref.read(appSettingsProvider).locale);
            },
          ),
        ),
        const Divider(
          thickness: 1,
        ),
        // const AppText.labelMedium('Router'),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: AppTextButton(
            loc(context).logout,
            onTap: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ),
        const AppGap.medium(),
      ];
    } else {
      return [];
    }
  }
}
