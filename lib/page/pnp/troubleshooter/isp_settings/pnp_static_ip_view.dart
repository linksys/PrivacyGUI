import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class PnpStaticIpView extends ConsumerStatefulWidget {
  const PnpStaticIpView({
    super.key,
  });

  @override
  ConsumerState<PnpStaticIpView> createState() => _PnpStaticIpViewState();
}

class _PnpStaticIpViewState extends ConsumerState<PnpStaticIpView> {
  final _ipController = TextEditingController();
  final _subnetController = TextEditingController();
  final _gatewayController = TextEditingController();
  final _dns1Controller = TextEditingController();
  final _dns2Controller = TextEditingController();
  var _hasExtraDNS = false;

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      scrollable: true,
      title: loc(context).static_ip_address,
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText.bodyLarge(
              'These settings are for users with a manually-assigned static IP address.',
            ),
            const AppGap.extraBig(),
            AppTextField.outline(
              headerText: loc(context).ipAddress,
              hintText: 'e.g. 192.168.1.1',
              controller: _ipController,
            ),
            const AppGap.semiBig(),
            AppTextField.outline(
              headerText: loc(context).subnetMask,
              hintText: 'e.g. 255.255.255.1',
              controller: _subnetController,
            ),
            const AppGap.semiBig(),
            AppTextField.outline(
              headerText: loc(context).defaultGateway,
              hintText: 'e.g. 192.168.0.1',
              controller: _gatewayController,
            ),
            const AppGap.semiBig(),
            AppTextField.outline(
              headerText: loc(context).dns1,
              hintText: 'e.g. 192.168.0.1',
              controller: _dns1Controller,
            ),
            Visibility(
              visible: _hasExtraDNS,
              replacement: Padding(
                padding: const EdgeInsets.only(
                  top: Spacing.extraBig,
                ),
                child: AppTextButton.noPadding(
                  '+ Add DNS',
                  onTap: () {
                    setState(() {
                      _hasExtraDNS = true;
                    });
                  },
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: Spacing.semiBig,
                ),
                child: AppTextField.outline(
                  headerText: 'DNS 2',
                  hintText: 'e.g. 192.168.0.1',
                  controller: _dns2Controller,
                ),
              ),
            ),
            const AppGap.extraBig(),
          ],
        ),
        footer: AppFilledButton.fillWidth(
          loc(context).next,
          onTap: () {
            //
          },
        ),
      ),
    );
  }
}
