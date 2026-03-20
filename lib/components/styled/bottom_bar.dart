import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/constants/url_links.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

class BottomBar extends ConsumerStatefulWidget {
  const BottomBar({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BottomBarState();
}

class _BottomBarState extends ConsumerState<BottomBar> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: IntrinsicHeight(
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          constraints: const BoxConstraints(minHeight: 56, maxHeight: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              const Divider(
                height: 1,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Semantics(
                              identifier: 'now-bottom-text-copyright',
                              child: AppText.bodySmall(loc(context)
                                  .copyRight(BuildConfig.copyRightYear))),
                        ),
                        AppButton.text(
                          label: loc(context).endUserLicenseAgreement,
                          key: const ValueKey('now-bottom-text-button-eula'),
                          size: AppButtonSize.small,
                          onTap: () {
                            gotoOfficialWebUrl(linkEULA,
                                locale: ref.read(appSettingsProvider).locale);
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: AppText.bodySmall('|'),
                        ),
                        AppButton.text(
                          label: loc(context).termsOfService,
                          key: const ValueKey('now-bottom-text-button-terms'),
                          size: AppButtonSize.small,
                          onTap: () {
                            gotoOfficialWebUrl(linkTerms,
                                locale: ref.read(appSettingsProvider).locale);
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: AppText.bodySmall('|'),
                        ),
                        AppButton.text(
                          label: loc(context).privacyAndSecurity,
                          key: const ValueKey('now-bottom-text-button-privacy'),
                          size: AppButtonSize.small,
                          onTap: () {
                            gotoOfficialWebUrl(linkPrivacy,
                                locale: ref.read(appSettingsProvider).locale);
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: AppText.bodySmall('|'),
                        ),
                        AppButton.text(
                          label: loc(context).thirdPartyLicenses,
                          key: const ValueKey(
                              'now-bottom-text-button-third-party'),
                          size: AppButtonSize.small,
                          onTap: () {
                            gotoOfficialWebUrl(linkThirdParty,
                                locale: ref.read(appSettingsProvider).locale);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
