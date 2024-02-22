import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/providers/auth/auth_provider.dart';
import 'package:linksys_app/core/cloud/model/region_code.dart';
import 'package:linksys_app/page/components/layouts/basic_header.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class RegionPickerView extends ArgumentsConsumerStatefulView {
  const RegionPickerView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  _RegionPickerViewState createState() => _RegionPickerViewState();
}

class _RegionPickerViewState extends ConsumerState<RegionPickerView> {
  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      appBarStyle: AppBarStyle.close,
      child: AppBasicLayout(
        header: const BasicHeader(
          title: 'Select region',
          description:
              'If your region is not listed, we can’t send text messages in your region yet.',
        ),
        content: FutureBuilder<List<RegionCode>>(
            future: ref.read(authProvider.notifier).fetchRegionCodes(),
            initialData: null,
            builder: (context, snapshot) {
              return snapshot.hasData
                  ? ListView.builder(
                      itemCount: snapshot.data?.length,
                      itemBuilder: (context, index) => InkWell(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: Spacing.regular),
                              child: Row(
                                children: [
                                  AppText.bodyLarge(
                                    '${snapshot.data?[index].flagCode}',
                                  ),
                                  const AppGap.semiSmall(),
                                  AppText.bodyMedium(
                                    '${snapshot.data?[index].countryName} +${snapshot.data?[index].countryCallingCode}',
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              context.pop(snapshot.data?[index]);
                            },
                          ))
                  : const AppFullScreenSpinner();
            }),
      ),
    );
  }
}
