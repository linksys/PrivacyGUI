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
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/providers/pnp_isp_settings_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

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
  bool _isLoading = false;

  final subnetMaskValidator = SubnetMaskValidator();
  final ipAddressValidator = IpAddressValidator();
  final requiredIpAddressValidator = IpAddressRequiredValidator();
  String? _ipError;
  String? _subnetError;
  String? _gatewayError;
  String? _dns1Error;
  String? _dns2Error;

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
      scrollable: true,
      title: loc(context).staticIPAddress,
      child: (context, constraints) => Column(
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
            errorText: _ipError,
            onFocusChanged: (isFocused) {
              if (!isFocused) {
                setState(() {
                  _ipError = ipAddressValidator.validate(_ipController.text)
                      ? null
                      : loc(context).invalidIpAddress;
                });
                isDataValidate();
              }
            },
          ),
          const AppGap.large2(),
          AppIPFormField(
            semanticLabel: 'subnet Mask',
            header: AppText.bodyLarge(
              loc(context).subnetMask,
            ),
            controller: _subnetController,
            border: const OutlineInputBorder(),
            errorText: _subnetError,
            onFocusChanged: (isFocused) {
              if (!isFocused) {
                setState(() {
                  _subnetError =
                      subnetMaskValidator.validate(_subnetController.text)
                          ? null
                          : loc(context).invalidSubnetMask;
                });
                isDataValidate();
              }
            },
          ),
          const AppGap.large2(),
          AppIPFormField(
            semanticLabel: 'default Gateway',
            header: AppText.bodyLarge(
              loc(context).defaultGateway,
            ),
            controller: _gatewayController,
            border: const OutlineInputBorder(),
            errorText: _gatewayError,
            onFocusChanged: (isFocused) {
              if (!isFocused) {
                setState(() {
                  _gatewayError =
                      ipAddressValidator.validate(_gatewayController.text)
                          ? null
                          : loc(context).invalidGatewayIpAddress;
                });
                isDataValidate();
              }
            },
          ),
          const AppGap.large2(),
          AppIPFormField(
            semanticLabel: 'dns 1',
            header: AppText.bodyLarge(
              loc(context).dns1,
            ),
            controller: _dns1Controller,
            border: const OutlineInputBorder(),
            errorText: _dns1Error,
            onFocusChanged: (isFocused) {
              if (!isFocused) {
                if (_dns1Controller.text.isNotEmpty) {
                  setState(() {
                    _dns1Error =
                        ipAddressValidator.validate(_dns1Controller.text)
                            ? null
                            : loc(context).invalidDns;
                  });
                } else {
                  setState(() {
                    _dns1Error = null;
                  });
                }
                isDataValidate();
              }
            },
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
                errorText: _dns2Error,
                onFocusChanged: (isFocused) {
                  if (!isFocused) {
                    if (_dns2Controller.text.isNotEmpty) {
                      setState(() {
                        _dns2Error =
                            ipAddressValidator.validate(_dns2Controller.text)
                                ? null
                                : loc(context).invalidDns;
                      });
                    } else {
                      setState(() {
                        _dns2Error = null;
                      });
                    }
                    isDataValidate();
                  }
                },
              ),
            ),
          ),
          const AppGap.large5(),
          AppFilledButton(
            loc(context).next,
            onTap: isDataValidate() ? onNext : null,
          ),
        ],
      ),
    );
  }

  bool isDataValidate() {
    final ipAddress = _ipController.text;
    final subnetMask = _subnetController.text;
    final gatewayIp = _gatewayController.text;
    final dns1 = _dns1Controller.text;
    final dns2 = _dns2Controller.text;

    return requiredIpAddressValidator.validate(ipAddress) &&
        subnetMaskValidator.validate(subnetMask) &&
        requiredIpAddressValidator.validate(gatewayIp) &&
        (dns1.isEmpty || ipAddressValidator.validate(dns1)) &&
        (dns2.isEmpty || ipAddressValidator.validate(dns2));
  }

  void onNext() async {
    logger.i('[PnP Troubleshooter]: Set the router into Static IP mode');
    final newState = ref.read(internetSettingsProvider).current.copyWith(
          ipv4Setting:
              ref.read(internetSettingsProvider).current.ipv4Setting.copyWith(
                    ipv4ConnectionType: WanType.static.type,
                    staticIpAddress: () => _ipController.text,
                    networkPrefixLength: () =>
                        NetworkUtils.subnetMaskToPrefixLength(
                      _subnetController.text,
                    ),
                    staticGateway: () => _gatewayController.text,
                    staticDns1: () => _dns1Controller.text,
                    staticDns2: () => _dns2Controller.text.isNotEmpty
                        ? _dns2Controller.text
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
