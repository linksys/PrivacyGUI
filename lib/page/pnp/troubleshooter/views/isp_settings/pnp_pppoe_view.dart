import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/advanced_settings/internet_settings/providers/_providers.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class PnpPPPOEView extends ArgumentsConsumerStatefulView {
  const PnpPPPOEView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<PnpPPPOEView> createState() => _PnpPPPOEViewState();
}

class _PnpPPPOEViewState extends ConsumerState<PnpPPPOEView> {
  final _accountNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _vlanController = TextEditingController();
  late bool hasVlanID;
  String? errorMessage;

  @override
  void initState() {
    hasVlanID = widget.args['needVlanId'] ?? false;
    super.initState();
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _passwordController.dispose();
    _vlanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: 'Enter ISP settings',
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText.bodyLarge(
              'Your PPPoE account name and password are provided by your Internet Service Provider (ISP). If you aren’t sure about yours, we recommend contacting your ISP.',
            ),
            const AppGap.extraBig(),
            if (errorMessage != null)
              AppText.bodyLarge(
                errorMessage!,
                color: Theme.of(context).colorScheme.error,
              ),
            const AppGap.extraBig(),
            AppTextField.outline(
              headerText: loc(context).accountName,
              controller: _accountNameController,
            ),
            const AppGap.semiBig(),
            AppTextField.outline(
              headerText: loc(context).password,
              controller: _passwordController,
            ),
            Visibility(
              visible: hasVlanID,
              replacement: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppGap.extraBig(),
                  AppTextButton.noPadding(
                    '+ Add VLAN ID',
                    onTap: () {
                      setState(() {
                        hasVlanID = true;
                      });
                    },
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppGap.semiBig(),
                  AppTextField.outline(
                    headerText: 'VLAN ID',
                    controller: _vlanController,
                    inputType: TextInputType.number,
                  ),
                  const AppGap.extraBig(),
                  AppTextButton.noPadding(
                    '- Remove VLAN ID',
                    onTap: () {
                      setState(() {
                        hasVlanID = false;
                      });
                    },
                  ),
                ],
              ),
            )
          ],
        ),
        footer: AppFilledButton.fillWidth(
          loc(context).next,
          onTap: _onNext,
        ),
      ),
    );
  }

  void _onNext() {
    var newState = ref.read(internetSettingsProvider).copyWith();
    newState = newState.copyWith(
      ipv4Setting: newState.ipv4Setting.copyWith(
        ipv4ConnectionType: WanType.pppoe.type,
        username: _accountNameController.text,
        password: _passwordController.text,
        vlanId: (hasVlanID && _vlanController.text.isNotEmpty)
            ? int.parse(_vlanController.text)
            : null,
      ),
    );
    context.pushNamed(
      RouteNamed.pnpIspSettingsAuth,
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