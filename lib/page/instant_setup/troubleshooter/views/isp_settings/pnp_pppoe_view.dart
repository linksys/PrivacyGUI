import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/_providers.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/providers/pnp_isp_settings_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:ui_kit_library/ui_kit.dart';

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

    if (error is ServiceSideEffectError) {
      final lastPolledResult = error.lastPolledResult;
      if (lastPolledResult != null && lastPolledResult is JNAPSuccess) {
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
      return AppFullScreenLoader(title: message);
    }

    return UiKitPageView.withSliver(
      title: loc(context).pnpPppoeTitle,
      child: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyLarge(
            loc(context).pnpPppoeDesc,
          ),
          AppGap.xxl(),
          AppGap.sm(),
          if (errorMessage != null)
            Padding(
              padding: EdgeInsets.only(
                bottom: AppSpacing.xxl + AppSpacing.sm,
              ),
              child: AppText.bodyLarge(
                errorMessage!,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          AppTextFormField(
            label: loc(context).accountName,
            controller: _accountNameController,
          ),
          AppGap.xl(),
          AppPasswordInput(
            label: loc(context).password,
            controller: _passwordController,
          ),
          Visibility(
            visible: hasVlanID,
            replacement: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppGap.xxxl(),
                AppButton.text(
                  label: loc(context).pnpPppoeAddVlan,
                  icon: AppIcon.font(AppFontIcons.add),
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
                AppGap.xl(),
                AppTextFormField(
                  label: loc(context).vlanIdOptional,
                  controller: _vlanController,
                ),
                AppGap.xxxl(),
                AppButton.text(
                  label: loc(context).pnpPppoeRemoveVlan,
                  icon: AppIcon.font(AppFontIcons.remove),
                  onTap: () {
                    setState(() {
                      hasVlanID = false;
                    });
                  },
                ),
              ],
            ),
          ),
          AppGap.xxl(),
          AppGap.sm(),
          AppButton(
            key: const Key('pnpPppoeNextButton'),
            label: loc(context).next,
            variant: SurfaceVariant.highlight,
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
