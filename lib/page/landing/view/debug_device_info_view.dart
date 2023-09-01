import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/page/components/layouts/basic_header.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
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
    getAppInfoLogs().then((value) {
      setState(() {
        _appInfoFromLogger = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      isCloseStyle: true,
      scrollable: true,
      child: AppBasicLayout(
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
        const AppGap.regular(),
        AppText.bodyLarge(
          getScreenInfo(context),
        ),
      ],
    );
  }
}
