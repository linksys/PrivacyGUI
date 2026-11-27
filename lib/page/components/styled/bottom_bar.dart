import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/constants/url_links.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

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
          color: Theme.of(context).colorScheme.background,
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
                              identifier: 'footer-copyright',
                              child: AppText.bodySmall(loc(context)
                                  .copyRight(BuildConfig.copyRightYear))),
                        ),
                        AppTextButton.noPadding(
                          loc(context).endUserLicenseAgreement,
                          identifier: 'footer-eula',
                          onTap: () {
                            gotoOfficialWebUrl(linkEULA,
                                locale: ref.read(appSettingsProvider).locale);
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: AppText.bodySmall('|'),
                        ),
                        AppTextButton.noPadding(
                          loc(context).termsOfService,
                          identifier: 'footer-terms',
                          onTap: () {
                            gotoOfficialWebUrl(linkTerms,
                                locale: ref.read(appSettingsProvider).locale);
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: AppText.bodySmall('|'),
                        ),
                        AppTextButton.noPadding(
                          loc(context).privacyAndSecurity,
                          identifier: 'footer-privacy',
                          onTap: () {
                            gotoOfficialWebUrl(linkPrivacy,
                                locale: ref.read(appSettingsProvider).locale);
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: AppText.bodySmall('|'),
                        ),
                        AppTextButton.noPadding(
                          loc(context).thirdPartyLicenses,
                          identifier: 'footer-third-party',
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
