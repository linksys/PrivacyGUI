import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/url_links.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_list.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacy_gui/util/cookie_helper/cookie_helper.dart'
    if (dart.library.io) 'package:privacy_gui/util/cookie_helper/cookie_helper_mobile.dart'
    if (dart.library.html) 'package:privacy_gui/util/cookie_helper/cookie_helper_web.dart';

class ExplanationView extends ArgumentsConsumerStatefulView {
  const ExplanationView({super.key, super.args});

  @override
  ConsumerState<ExplanationView> createState() => _ExplanationViewState();
}

class _ExplanationViewState extends ConsumerState<ExplanationView> {
  final contunueKey = GlobalKey();
  bool _dontShow = false;

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      backState: StyledBackState.none,
      scrollable: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleLarge(loc(context).explanationTitle),
          const AppGap.large2(),
          AppText.bodyLarge(loc(context).explanationdesc),
          const AppGap.large2(),
          AppBulletList(children: [
            AppText.bodyLarge(loc(context).explanationProblem1),
            AppText.bodyLarge(loc(context).explanationProblem2),
          ]),
          const AppGap.large2(),
          AppText.bodyLarge(loc(context).explanationError),
          const AppGap.large2(),
          const AppBulletList(children: [
            AppText.bodyLarge('NET::ERR_CERT_AUTHORITY_INVALID'),
            AppText.bodyLarge('ERR_CERT_AUTHORITY_INVALID'),
            AppText.bodyLarge('SEC_ERROR_UNKNOWN_ISSUER'),
          ]),
          const AppGap.large2(),
          AppText.bodyLarge(loc(context).explanationExample),
          const AppGap.large2(),
          Image(image: CustomTheme.of(context).images.chromePrivacyErr),
          const AppGap.large2(),
          AppText.titleLarge(loc(context).explanationWhyIAmSeeingThis),
          const AppGap.large2(),
          AppText.bodyLarge(loc(context).explanationWhyIAmSeeingThisDesc),
          AppTextButton.noPadding(
            loc(context).learnMore,
            onTap: () {
              gotoOfficialWebUrl(linksysCertExplanation,
                  locale: ref.read(appSettingsProvider).locale);
            },
          ),
          const AppGap.large2(),
          AppText.titleLarge(loc(context).explanationHowCanIBypass),
          const AppGap.large2(),
          AppStyledText(
            loc(context).explanationHowCanIBypassDesc,
            defaultTextStyle: Theme.of(context).textTheme.bodyLarge!,
            callbackTags: {
              'a': (_, __) {
                Scrollable.ensureVisible(contunueKey.currentContext!,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut);
              }
            },
            styleTags: {
              'a': Theme.of(context)
                  .textTheme
                  .labelLarge!
                  .copyWith(color: Theme.of(context).colorScheme.primary),
            },
          ),
          const AppGap.large2(),
          AppText.labelLarge(loc(context).googleChrome),
          const AppGap.medium(),
          AppStyledText.bold(
            loc(context).googleChromeStep,
            defaultTextStyle: Theme.of(context).textTheme.bodyLarge!,
            tags: const ['b'],
          ),
          const AppGap.large2(),
          AppText.labelLarge(loc(context).mozillaFirefox),
          const AppGap.medium(),
          AppStyledText.bold(
            loc(context).mozillaFirefoxDesc,
            defaultTextStyle: Theme.of(context).textTheme.bodyLarge!,
            tags: const ['b'],
          ),
          const AppGap.large2(),
          AppText.labelLarge(loc(context).microsoftEdge),
          const AppGap.medium(),
          AppStyledText.bold(
            loc(context).microsoftEdgeDesc,
            defaultTextStyle: Theme.of(context).textTheme.bodyLarge!,
            tags: const ['b'],
          ),
          const AppGap.large2(),
          AppText.labelLarge(loc(context).safari),
          const AppGap.medium(),
          AppStyledText.bold(
            loc(context).safariDesc,
            defaultTextStyle: Theme.of(context).textTheme.bodyLarge!,
            tags: const ['b'],
          ),
          const AppGap.large2(),
          AppFilledButton(
            key: contunueKey,
            loc(context).textContinue,
            onTap: () {
              context.goNamed(RouteNamed.pnp);
            },
          ),
          const AppGap.large2(),
          AppCheckbox(
            value: _dontShow,
            text: loc(context).doNotShowThisAgain,
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _dontShow = value;
              });
              setCookies(value);
            },
          ),
          const AppGap.large5(),
          AppText.titleLarge(loc(context).questions),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.medium),
            child: AppTextButton.noPadding(
              loc(context).pnpNoInternetConnectionContactSupport,
              onTap: () {
                gotoOfficialWebUrl(linkSupport,
                    locale: ref.read(appSettingsProvider).locale);
              },
            ),
          ),
          const AppGap.large5(),
        ],
      ),
    );
  }

  void setCookies(bool isSet) {
    const name = 'skip-http-blocking';
    final value = isSet ? 'true' : '';
    final expires = isSet
        ? (DateTime.now()..add(const Duration(days: 3650)).toIso8601String())
        : null;
    const path = RoutePath.explanation;
    setCookie('$name=$value');
  }
}
