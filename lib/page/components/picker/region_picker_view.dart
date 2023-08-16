import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/provider/auth/auth_provider.dart';
import 'package:linksys_moab/core/cloud/model/region_code.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
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
      isCloseStyle: true,
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
                            child: AppPadding(
                              padding: const AppEdgeInsets.symmetric(
                                  vertical: AppGapSize.regular),
                              child: Row(
                                children: [
                                  AppText.descriptionMain(
                                    '${snapshot.data?[index].flagCode}',
                                  ),
                                  const AppGap.semiSmall(),
                                  AppText.descriptionSub(
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
