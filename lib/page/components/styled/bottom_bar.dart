import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacy_gui/util/url_helper/url_helper.dart'
    if (dart.library.io) 'package:privacy_gui/util/url_helper/url_helper_mobile.dart'
    if (dart.library.html) 'package:privacy_gui/util/url_helper/url_helper_web.dart';

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
                              identifier: 'now-bottom-text-copyright',
                              child: AppText.bodySmall(
                                  loc(context).copyRight(2024))),
                        ),
                        AppTextButton.noPadding(
                          loc(context).endUserLicenseAgreement,
                          identifier: 'now-bottom-text-button-eula',
                          onTap: () {
                            openUrl('https://store.linksys.com/EULA.html');
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: AppText.bodySmall('|'),
                        ),
                        AppTextButton.noPadding(
                          loc(context).termsOfService,
                          identifier: 'now-bottom-text-button-terms',
                          onTap: () {
                            openUrl('https://store.linksys.com/terms.html');
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: AppText.bodySmall('|'),
                        ),
                        AppTextButton.noPadding(
                          loc(context).privacyAndSecurity,
                          identifier: 'now-bottom-text-button-privacy',
                          onTap: () {
                            // TODO languages?
                            openUrl(
                                'https://store.linksys.com/support-article?articleNum=47763');
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: AppText.bodySmall('|'),
                        ),
                        AppTextButton.noPadding(
                          loc(context).thirdPartyLicenses,
                          identifier: 'now-bottom-text-button-third-party',
                          onTap: () {
                            openUrl(
                                'https://store.linksys.com/privacy-and-security.html');
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
