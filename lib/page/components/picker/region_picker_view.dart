import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/core/cloud/model/region_code.dart';
import 'package:privacy_gui/page/components/layouts/basic_header.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

class RegionPickerView extends ArgumentsConsumerStatefulView {
  const RegionPickerView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<RegionPickerView> createState() => _RegionPickerViewState();
}

class _RegionPickerViewState extends ConsumerState<RegionPickerView> {
  @override
  Widget build(BuildContext context) {
    return StyledAppPageView.withSliver(
      appBarStyle: AppBarStyle.close,
      child: (context, constraints) => Column(
        children: [
          const BasicHeader(
            title: 'Select region',
            description:
                'If your region is not listed, we can’t send text messages in your region yet.',
          ),
         FutureBuilder<List<RegionCode>>(
            future: ref.read(authProvider.notifier).fetchRegionCodes(),
            initialData: null,
            builder: (context, snapshot) {
              return snapshot.hasData
                  ? ListView.builder(
                      itemCount: snapshot.data?.length,
                      itemBuilder: (context, index) => InkWell(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: Spacing.medium),
                              child: Row(
                                children: [
                                  AppText.bodyLarge(
                                    '${snapshot.data?[index].flagCode}',
                                  ),
                                  const AppGap.small2(),
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
            }),],
      ),
    );
  }
}
