import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/constants/url_links.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/localization/localization_hook.dart';

import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/general_settings_widget/language_tile.dart';
import 'package:privacy_gui/page/components/styled/general_settings_widget/theme_mode_tile.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';

import 'package:ui_kit_library/ui_kit.dart';

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
    final isRemote = loginType == LoginType.remote;

    // Watch Theme.of(context) to trigger rebuild when global theme changes
    Theme.of(context);

    // Use dark theme's color scheme for icon color
    final darkTheme = getIt.get<ThemeData>(instanceName: 'darkThemeData');
    final colorScheme = darkTheme.colorScheme;

    return AppPopupButton(
      maxWidth: 240,
      position: PopupVerticalPosition.bottom,
      button: Semantics(
        identifier: 'now-topbar-icon-general-settings',
        label: 'general settings',
        child: Icon(
          isRemote ? Icons.support_agent : AppFontIcons.person,
          size: 20,
          color: colorScheme.onSurface,
        ),
      ),
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      builder: (controller) {
        final locale =
            ref.watch(appSettingsProvider.select((value) => value.locale));
        return Semantics(
          explicitChildNodes: true,
          child: AppSurface(
            padding: const EdgeInsets.all(8.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 200, maxWidth: 240),
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
                            .update(appSettings.copyWith(locale: () => locale));
                      },
                    ),
                  ),
                  AppGap.lg(),
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: Semantics(
                      identifier: 'now-general-settings-theme',
                      label: 'theme',
                      child: const ThemeModeTile(),
                    ),
                  ),
                  // const AppGap.lg(),
                  // Padding(
                  //   padding: EdgeInsets.all(AppSpacing.sm),
                  //   child: Semantics(
                  //     identifier: 'now-general-settings-theme-color',
                  //     label: 'themeColor',
                  //     child: const ThemeColorTile(),
                  //   ),
                  // ),
                  AppGap.lg(),
                  ..._displayAdditional(loginType, controller),
                  FutureBuilder(
                      future: getVersion(),
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
          ),
        );
      },
    );
  }

  List<Widget> _displayAdditional(
      LoginType loginType, AppPopupController controller) {
    final isRemote = loginType == LoginType.remote;
    if (loginType != LoginType.none) {
      return [
        // Padding(
        //   padding: const EdgeInsets.all(8.0),
        //   child: AppButton.text(
        //     label: loc(context).endUserLicenseAgreement,
        //     onTap: () {
        //       gotoOfficialWebUrl(linkEULA,
        //           locale: ref.read(appSettingsProvider).locale);
        //     },
        //   ),
        // ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: AppButton.text(
            label: loc(context).termsOfService,
            onTap: () {
              gotoOfficialWebUrl(linkTerms,
                  locale: ref.read(appSettingsProvider).locale);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: AppButton.text(
            label: loc(context).thirdPartyLicenses,
            onTap: () {
              gotoOfficialWebUrl(linkThirdParty,
                  locale: ref.read(appSettingsProvider).locale);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: AppButton.text(
            label: loc(context).privacyAndSecurity,
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
          child: AppButton.dangerText(
            label: isRemote
                ? loc(context).endRemoteAssistance
                : loc(context).logout,
            onTap: isRemote
                ? () {
                    controller.close();
                    showSimpleAppDialog(
                      context,
                      title: loc(context).endRemoteAssistance,
                      content: AppText.bodyMedium(
                          loc(context).endRemoteAssistanceDesc),
                      actions: [
                        AppButton.text(
                          label: loc(context).cancel,
                          onTap: () {
                            context.pop();
                          },
                        ),
                        AppButton.dangerText(
                          label: loc(context).ok,
                          onTap: () {
                            logger.i('[Auth]: The user manually end session');
                            context.pop();
                            ref
                                .read(remoteClientProvider.notifier)
                                .endRemoteAssistance();
                            ref.read(authProvider.notifier).logout();
                          },
                        ),
                      ],
                    );
                  }
                : () {
                    logger.i('[Auth]: The user manually logs out');
                    ref.read(authProvider.notifier).logout();
                  },
          ),
        ),
        AppGap.lg(),
      ];
    } else {
      return [];
    }
  }
}
