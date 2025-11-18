import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/_providers.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/providers/pnp_isp_settings_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

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
  bool _isLoading = false;

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

  String _getErrorMessage(WanType wanType) {
    if (wanType == WanType.static || wanType == WanType.dhcp) {
      return loc(context).pnpErrorForStaticIpAndDhcp;
    } else {
      // This case must be PPPOE
      return loc(context).pnpErrorForPppoe;
    }
  }

  void _handleError(Object error, WanType wanType) {
    if (!mounted) return;

    if (error is JNAPSideEffectError) {
      final lastHandledResult = error.lastHandledResult;
      if (lastHandledResult != null && lastHandledResult is JNAPSuccess) {
        setState(() {
          errorMessage = _getErrorMessage(wanType);
        });
      } else {
        showRouterNotFoundAlert(context, ref, onComplete: () async {
          context.goNamed(RouteNamed.pnp);
        });
      }
    } else if (error is JNAPError) {
      setState(() {
        errorMessage =
            errorCodeHelper(context, error.result, _getErrorMessage(wanType)) ??
                _getErrorMessage(wanType);
      });
    } else if (error is ExceptionNoInternetConnection) {
      setState(() {
        errorMessage = _getErrorMessage(wanType);
      });
    } else {
      setState(() {
        errorMessage = _getErrorMessage(wanType);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pnpIspSettingsProvider);
    if (_isLoading) {
      final message = switch (state) {
        PnpIspSettingsStatus.saving => loc(context).savingChanges,
        PnpIspSettingsStatus.checkSettings => loc(context).launchCheckInternet,
        PnpIspSettingsStatus.checkInternetConnection =>
          loc(context).launchCheckInternet,
        PnpIspSettingsStatus.success => loc(context).successExclamation,
        PnpIspSettingsStatus.error => loc(context).error,
        _ => loc(context).savingChanges,
      };
      return AppFullScreenSpinner(text: message);
    }

    return StyledAppPageView.withSliver(
      title: loc(context).pnpPppoeTitle,
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
    final newState = ref.read(internetSettingsProvider).current.copyWith(
          ipv4Setting:
              ref.read(internetSettingsProvider).current.ipv4Setting.copyWith(
                    ipv4ConnectionType: WanType.pppoe.type,
                    username: () => _accountNameController.text,
                    password: () => _passwordController.text,
                    vlanId: () => (hasVlanID && _vlanController.text.isNotEmpty)
                        ? int.parse(_vlanController.text)
                        : null,
                  ),
        );

    setState(() {
      _isLoading = true;
      errorMessage = null;
    });
    try {
      await ref
          .read(pnpIspSettingsProvider.notifier)
          .saveAndVerifySettings(newState);
      if (mounted) {
        context.goNamed(RouteNamed.pnp);
      }
    } catch (e) {
      final wanType = WanType.resolve(
        newState.ipv4Setting.ipv4ConnectionType,
      )!;
      _handleError(e, wanType);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
