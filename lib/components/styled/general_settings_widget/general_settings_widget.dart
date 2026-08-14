import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/constants/url_links.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/localization/localization_hook.dart';

import 'package:privacy_gui/components/styled/general_settings_widget/language_tile.dart';
import 'package:privacy_gui/components/styled/general_settings_widget/theme_mode_tile.dart';
import 'package:privacy_gui/localization/supported_locales_provider.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/config/global_config.dart';

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
    final isLoggedIn = ref.watch(
        authProvider.select((state) => state.value?.isLoggedIn ?? false));

    // Watch Theme.of(context) to trigger rebuild when global theme changes
    Theme.of(context);

    // Use dark theme's color scheme for icon color
    final darkTheme = getIt.get<ThemeData>(instanceName: 'darkThemeData');
    final colorScheme = darkTheme.colorScheme;

    return AppPopupButton(
      maxWidth: 280,
      position: PopupVerticalPosition.bottom,
      button: Semantics(
        identifier: 'now-topbar-icon-general-settings',
        label: 'general settings',
        child: Icon(
          AppFontIcons.person,
          size: 20,
          color: colorScheme.onSurface,
        ),
      ),
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      builder: (controller) {
        // Normalized, so the tile cannot read "日本語" with no row check-marked
        // while the app renders English — which is what a persisted `ja` did on a
        // build that no longer ships it.
        final locale = ref.watch(activeLocaleProvider);
        final showMascot =
            ref.watch(appSettingsProvider.select((value) => value.showMascot));
        return Semantics(
          explicitChildNodes: true,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 240, maxWidth: 280),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Language — omitted when the build ships a single language
                  // pack, because there is nothing to pick between. The parent
                  // has to make this call rather than the tile self-hiding, or
                  // the fixed-height SizedBox leaves a 44px hole behind.
                  if (ref.watch(canPickLanguageProvider))
                    SizedBox(
                      height: 44,
                      child: LanguageTile(
                        locale: locale,
                        onTap: () {
                          controller.close();
                        },
                        onSelected: (locale) {
                          final appSettings = ref.read(appSettingsProvider);
                          ref.read(appSettingsProvider.notifier).update(
                              appSettings.copyWith(locale: () => locale));
                        },
                      ),
                    ),

                  // Theme
                  SizedBox(
                    height: 44,
                    child: Semantics(
                      identifier: 'now-general-settings-theme',
                      label: 'theme',
                      child: ThemeModeTile(
                        onTap: () {
                          controller.close();
                        },
                        onSelected: (mode) {
                          final appSettings = ref.read(appSettingsProvider);
                          ref
                              .read(appSettingsProvider.notifier)
                              .update(appSettings.copyWith(themeMode: mode));
                        },
                      ),
                    ),
                  ),

                  // Mascot toggle — gated by the same flag as the overlay so
                  // the two never diverge (hidden in remote mode and E2E mock
                  // builds; a toggle for a hidden mascot would be dead). (P0-2)
                  if (GlobalConfig.remote.mascotEnabled)
                    SizedBox(
                      height: 44,
                      child: _buildMascotToggle(showMascot),
                    ),

                  // Legal links and logout (hidden in remote mode)
                  if (!GlobalConfig.remote.isActive && isLoggedIn) ...[
                    AppGap.md(),
                    const AppDivider(),
                    AppGap.md(),

                    // Legal links as compact row
                    _buildLegalLinks(),
                    AppGap.lg(),

                    // Logout
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.dangerOutline(
                        label: loc(context).logout,
                        onTap: () {
                          logger.i('[Auth]: The user manually logs out');
                          ref.read(authProvider.notifier).logout();
                        },
                      ),
                    ),
                  ],
                  AppGap.lg(),

                  // Version
                  FutureBuilder(
                    future: getVersion(),
                    initialData: '-',
                    builder: (context, data) {
                      return Semantics(
                        identifier: 'now-general-text-version',
                        label: 'version',
                        child: Center(
                          child: AppText.bodySmall(
                            'version ${data.data}',
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMascotToggle(bool showMascot) {
    return Semantics(
      identifier: 'now-general-settings-mascot',
      label: 'mascot',
      child: Row(
        children: [
          const Icon(Icons.pets, size: 20),
          AppGap.lg(),
          Expanded(
            child: AppText.labelMedium(loc(context).showMascot),
          ),
          AppSwitch(
            value: showMascot,
            scale: 0.8,
            onChanged: (value) {
              final appSettings = ref.read(appSettingsProvider);
              ref
                  .read(appSettingsProvider.notifier)
                  .update(appSettings.copyWith(showMascot: value));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegalLinks() {
    // The normalized locale, not the raw setting: an English-only build reading a
    // leftover `ja` would open linksys.com/jp/… for a user whose picker is hidden.
    final locale = ref.read(activeLocaleProvider);

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        AppButton.text(
          label: loc(context).termsOfService,
          size: AppButtonSize.small,
          onTap: () => gotoOfficialWebUrl(linkTerms, locale: locale),
        ),
        AppButton.text(
          label: loc(context).thirdPartyLicenses,
          size: AppButtonSize.small,
          onTap: () => gotoOfficialWebUrl(linkThirdParty, locale: locale),
        ),
        AppButton.text(
          label: loc(context).privacyAndSecurity,
          size: AppButtonSize.small,
          onTap: () => gotoOfficialWebUrl(linkPrivacy, locale: locale),
        ),
      ],
    );
  }
}
