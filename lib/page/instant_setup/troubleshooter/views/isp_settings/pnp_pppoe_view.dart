import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/_providers.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

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
      title: loc(context).pnpPppoeTitle,
      scrollable: true,
      child: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyLarge(
            loc(context).pnpPppoeDesc,
          ),
          const AppGap.large3(),
          const AppGap.small2(),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(
                bottom: Spacing.large3 + Spacing.small2,
              ),
              child: AppText.bodyLarge(
                errorMessage!,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          AppTextField.outline(
            headerText: loc(context).accountName,
            controller: _accountNameController,
          ),
          const AppGap.large2(),
          AppTextField.outline(
            secured: true,
            headerText: loc(context).password,
            controller: _passwordController,
          ),
          Visibility(
            visible: hasVlanID,
            replacement: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppGap.large5(),
                AppTextButton.noPadding(
                  loc(context).pnpPppoeAddVlan,
                  icon: LinksysIcons.add,
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
                const AppGap.large2(),
                AppTextField.outline(
                  headerText: loc(context).vlanIdOptional,
                  controller: _vlanController,
                  inputType: TextInputType.number,
                ),
                const AppGap.large5(),
                AppTextButton.noPadding(
                  loc(context).pnpPppoeRemoveVlan,
                  icon: LinksysIcons.remove,
                  onTap: () {
                    setState(() {
                      hasVlanID = false;
                    });
                  },
                ),
              ],
            ),
          ),
          const AppGap.large3(),
          const AppGap.small2(),
          AppFilledButton(
            loc(context).next,
            onTap: _onNext,
          ),
        ],
      ),
    );
  }

  void _onNext() async {
    logger.i('[PnP Troubleshooter]: Set the router into PPPOE mode');
    var newState = ref.read(internetSettingsProvider).copyWith();
    newState = newState.copyWith(
      ipv4Setting: newState.ipv4Setting.copyWith(
        ipv4ConnectionType: WanType.pppoe.type,
        username: () => _accountNameController.text,
        password: () => _passwordController.text,
        vlanId: () => (hasVlanID && _vlanController.text.isNotEmpty)
            ? int.parse(_vlanController.text)
            : null,
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
