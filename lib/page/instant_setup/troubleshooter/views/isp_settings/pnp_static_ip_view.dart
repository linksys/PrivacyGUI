import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/_providers.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';

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
  String? errorMessage;

  @override
  void dispose() {
    _ipController.dispose();
    _subnetController.dispose();
    _gatewayController.dispose();
    _dns1Controller.dispose();
    _dns2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      scrollable: true,
      title: loc(context).staticIPAddress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyLarge(
            loc(context).pnpStaticIpDesc,
          ),
          const AppGap.large4(),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(
                bottom: Spacing.large4,
              ),
              child: AppText.bodyLarge(
                errorMessage!,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          AppIPFormField(
            semanticLabel: 'ip Address',
            header: AppText.bodyLarge(
              loc(context).ipAddress,
            ),
            controller: _ipController,
            border: const OutlineInputBorder(),
            onFocusChanged: (isFocused) {},
          ),
          const AppGap.large2(),
          AppIPFormField(
            semanticLabel: 'subnet Mask',
            header: AppText.bodyLarge(
              loc(context).subnetMask,
            ),
            controller: _subnetController,
            border: const OutlineInputBorder(),
          ),
          const AppGap.large2(),
          AppIPFormField(
            semanticLabel: 'default Gateway',
            header: AppText.bodyLarge(
              loc(context).defaultGateway,
            ),
            controller: _gatewayController,
            border: const OutlineInputBorder(),
          ),
          const AppGap.large2(),
          AppIPFormField(
            semanticLabel: 'dns 1',
            header: AppText.bodyLarge(
              loc(context).dns1,
            ),
            controller: _dns1Controller,
            border: const OutlineInputBorder(),
          ),
          Visibility(
            visible: _hasExtraDNS,
            replacement: Padding(
              padding: const EdgeInsets.only(
                top: Spacing.large5,
              ),
              child: AppTextButton.noPadding(
                loc(context).addDns,
                onTap: () {
                  setState(() {
                    _hasExtraDNS = true;
                  });
                },
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                top: Spacing.large2,
              ),
              child: AppIPFormField(
                semanticLabel: 'dns 2 Optional',
                header: AppText.bodyLarge(
                  loc(context).dns2Optional,
                ),
                controller: _dns2Controller,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const AppGap.large5(),
          AppFilledButton(
            loc(context).next,
            onTap: onNext,
          ),
        ],
      ),
    );
  }

  void onNext() async {
    logger.i('[PnP Troubleshooter]: Set the router into Static IP mode');
    var newState = ref.read(internetSettingsProvider).copyWith();
    newState = newState.copyWith(
      ipv4Setting: newState.ipv4Setting.copyWith(
        ipv4ConnectionType: WanType.static.type,
        staticIpAddress: () => _ipController.text,
        networkPrefixLength: () => NetworkUtils.subnetMaskToPrefixLength(
          _subnetController.text,
        ),
        staticGateway: () => _gatewayController.text,
        staticDns1: () => _dns1Controller.text,
        staticDns2:
            () => _dns2Controller.text.isNotEmpty ? _dns2Controller.text : null,
      ),
    );

    context.pushNamed(
      RouteNamed.pnpIspSaveSettings,
      extra: {'newSettings': newState},
    ).then((error) {
      if (error is String) {
        setState(() {
          errorMessage = error;
        });
      }
    });
  }
}
