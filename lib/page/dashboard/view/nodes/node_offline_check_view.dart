import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/node/cubit.dart';
import 'package:linksys_moab/bloc/node/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class NodeOfflineCheckView extends ArgumentsConsumerStatefulView {
  const NodeOfflineCheckView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<NodeOfflineCheckView> createState() =>
      _NodeOfflineCheckViewState();
}

class _NodeOfflineCheckViewState extends ConsumerState<NodeOfflineCheckView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      isCloseStyle: true,
      scrollable: true,
      child: AppBasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).node_offline_check_title,
        ),
        content: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Image.asset(
                  'assets/images/img_topology_node.png',
                  width: 74,
                  height: 74,
                ),
                const AppGap.regular(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocBuilder<NodeCubit, NodeState>(
                        builder: (context, state) {
                      return AppText.descriptionMain(
                        state.location,
                      );
                    }),
                    AppText.descriptionSub(
                      getAppLocalizations(context).offline,
                    )
                  ],
                )
              ],
            ),
            const AppGap.big(),
            AppText.descriptionSub(
              getAppLocalizations(context).node_offline_power_is_on,
            ),
            const AppGap.semiSmall(),
            AppText.descriptionSub(
              getAppLocalizations(context).node_offline_power_is_on_description,
            ),
            const AppGap.regular(),
            AppText.descriptionSub(
              getAppLocalizations(context).node_offline_within_range,
            ),
            const AppGap.semiSmall(),
            AppText.descriptionSub(
              getAppLocalizations(context)
                  .node_offline_within_range_description,
            ),
            const AppGap.regular(),
            AppText.descriptionSub(
              getAppLocalizations(context).node_offline_still_offline,
            ),
            const AppGap.semiSmall(),
            AppText.descriptionSub(
              getAppLocalizations(context)
                  .node_offline_still_offline_description,
            ),
          ],
        ),
      ),
    );
  }
}
