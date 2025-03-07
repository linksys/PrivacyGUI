import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/components/layouts/basic_header.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import '../../../core/utils/logger.dart';

class DebugDeviceInfoView extends ConsumerStatefulWidget {
  const DebugDeviceInfoView({Key? key}) : super(key: key);

  @override
  ConsumerState<DebugDeviceInfoView> createState() =>
      _DebugDeviceInfoViewState();
}

class _DebugDeviceInfoViewState extends ConsumerState<DebugDeviceInfoView> {
  String _appInfoFromLogger = '';

  _DebugDeviceInfoViewState() {
    getPackageInfo().then((value) {
      setState(() {
        _appInfoFromLogger = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      appBarStyle: AppBarStyle.close,
      scrollable: true,
      child: (context, constraints, scrollController) =>AppBasicLayout(
        header: const BasicHeader(
          title: 'Device Information',
        ),
        content: _information(context),
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }

  Widget _information(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyLarge(
          _appInfoFromLogger,
        ),
        const AppGap.medium(),
        AppText.bodyLarge(
          getScreenInfo(context),
        ),
      ],
    );
  }
}
