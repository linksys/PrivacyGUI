import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import '../../../util/logger.dart';

class DebugDeviceInfoView extends StatefulWidget {
  const DebugDeviceInfoView({Key? key}): super(key: key);

  @override
  State<StatefulWidget> createState() => _DebugDeviceInfoViewState();
}

class _DebugDeviceInfoViewState extends State<DebugDeviceInfoView> {
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
    return BasePageView.withCloseButton(
      context,
      scrollable: true,
      child: BasicLayout(
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
      children: [
        Text(
          _appInfoFromLogger,
          style: Theme.of(context).textTheme.headline3?.copyWith(
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        Text(
          getScreenInfo(context),
          style: Theme.of(context).textTheme.headline3?.copyWith(
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}