import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/providers/app_settings/app_settings_provider.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_app/util/url_helper/url_helper.dart'
    if (dart.library.io) 'package:linksys_app/util/url_helper/url_helper_mobile.dart'
    if (dart.library.html) 'package:linksys_app/util/url_helper/url_helper_web.dart';

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
          constraints: BoxConstraints(minHeight: 56, maxHeight: 60),
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
                          child: AppText.bodySmall(
                              '© 2024 Linksys Holdings, Inc. and/or its affiliates. All rights reserved.'),
                        ),
                        AppTextButton.noPadding(
                          'End User License Agreement',
                          onTap: () {
                            openUrl(
                                'https://www.linksys.com/support-article?articleNum=48056');
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: AppText.bodySmall('|'),
                        ),
                        AppTextButton.noPadding(
                          'Terms of Service',
                          onTap: () {
                            openUrl(
                                'https://www.linksys.com/support-article?articleNum=48053');
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: AppText.bodySmall('|'),
                        ),
                        AppTextButton.noPadding(
                          'Privacy Statement',
                          onTap: () {
                            // TODO languages?
                            openUrl(
                                'https://www.linksys.com/support-article/?articleNum=48370');
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: AppText.bodySmall('|'),
                        ),
                        AppTextButton.noPadding(
                          'Third Party License',
                          onTap: () {},
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
