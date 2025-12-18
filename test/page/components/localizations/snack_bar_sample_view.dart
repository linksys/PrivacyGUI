import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:ui_kit_library/ui_kit.dart';

class SnackBarSampleView extends ArgumentsConsumerStatefulView {
  // final String text;
  const SnackBarSampleView({
    // required this.text,
    super.key,
    super.args,
  });

  @override
  ConsumerState<SnackBarSampleView> createState() => _SnackBarSampleViewState();
}

class _SnackBarSampleViewState extends ConsumerState<SnackBarSampleView> {
  @override
  Widget build(BuildContext context) {
    return UiKitPageView(
      scrollable: true,
      backState: UiKitBackState.none,
      title: 'Snack Bar Sample',
      bottomBar: UiKitBottomBarConfig(
        isPositiveEnabled: false,
        onPositiveTap: () {},
      ),
      child: (context, constraints) => Column(
        children: [
          CustomScrollView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    Column(
                      children: [
                        AppButton.text(
                          label: 'Success: Saved',
                          onTap: () {
                            showSuccessSnackBar(context, loc(context).saved);
                          },
                        ),
                        AppButton.text(
                          label: 'Success: Changes saved',
                          onTap: () {
                            showSuccessSnackBar(
                                context, loc(context).changesSaved);
                          },
                        ),
                        AppButton.text(
                          label: 'Success: Success!',
                          onTap: () {
                            showSuccessSnackBar(
                                context, loc(context).successExclamation);
                          },
                        ),
                        AppButton.text(
                          label: 'Success: Copied to clipboard!',
                          onTap: () {
                            showSuccessSnackBar(
                                context, loc(context).sharedCopied);
                          },
                        ),
                        AppButton.text(
                          label: 'Success: Done',
                          onTap: () {
                            showSuccessSnackBar(context, loc(context).done);
                          },
                        ),
                        AppButton.text(
                          label: 'Success: Router password updated',
                          onTap: () {
                            showSuccessSnackBar(
                                context, loc(context).passwwordUpdated);
                          },
                        ),
                      ],
                    ),
                    AppGap.sm(),
                    Column(
                      children: [
                        AppButton.text(
                          label: 'Failed: Failed!',
                          onTap: () {
                            showFailedSnackBar(
                              context,
                              loc(context).failedExclamation,
                            );
                          },
                        ),
                        AppButton.text(
                          label: 'Failed: Invalid admin password',
                          onTap: () {
                            showFailedSnackBar(
                              context,
                              loc(context).invalidAdminPassword,
                            );
                          },
                        ),
                        AppButton.text(
                          label: 'Failed: Invalid firmware file!',
                          onTap: () {
                            showFailedSnackBar(
                              context,
                              loc(context)
                                  .errorManualUpdateSignatureCheckFailed,
                            );
                          },
                        ),
                        AppButton.text(
                          label: 'Failed: Error manual update failed!',
                          onTap: () {
                            showFailedSnackBar(
                              context,
                              loc(context).errorManualUpdateFailed,
                            );
                          },
                        ),
                        AppButton.text(
                          label: 'Failed: IP address or MAC address overlap',
                          onTap: () {
                            showFailedSnackBar(
                              context,
                              loc(context).ipOrMacAddressOverlap,
                            );
                          },
                        ),
                        AppButton.text(
                          label:
                              'Failed: Oops, something wrong here! Please try again later',
                          onTap: () {
                            showFailedSnackBar(
                              context,
                              loc(context).generalError,
                            );
                          },
                        ),
                        AppButton.text(
                          label: 'Failed: Unknown error',
                          onTap: () {
                            showFailedSnackBar(
                              context,
                              loc(context).unknownError,
                            );
                          },
                        ),
                        AppButton.text(
                          label: 'Failed: Incorrect password',
                          onTap: () {
                            showFailedSnackBar(
                              context,
                              errorCodeHelper(context, errorInvalidPassword) ??
                                  '',
                            );
                          },
                        ),
                        AppButton.text(
                          label: 'Failed: Too many failed attempts',
                          onTap: () {
                            showFailedSnackBar(
                              context,
                              errorCodeHelper(
                                      context, errorAdminAccountLocked) ??
                                  '',
                            );
                          },
                        ),
                        AppButton.text(
                          label: 'Failed: Invalid destination MAC address',
                          onTap: () {
                            showFailedSnackBar(
                              context,
                              errorCodeHelper(context,
                                      errorInvalidDestinationMACAddress) ??
                                  '',
                            );
                          },
                        ),
                        AppButton.text(
                          label: 'Failed: Invalid destination IP address',
                          onTap: () {
                            showFailedSnackBar(
                              context,
                              errorCodeHelper(context,
                                      errorInvalidDestinationIpAddress) ??
                                  '',
                            );
                          },
                        ),
                        AppButton.text(
                          label: 'Failed: Invalid gateway IP address',
                          onTap: () {
                            showFailedSnackBar(
                              context,
                              errorCodeHelper(context, errorInvalidGateway) ??
                                  '',
                            );
                          },
                        ),
                        AppButton.text(
                          label: 'Failed: Invalid IP address',
                          onTap: () {
                            showFailedSnackBar(
                              context,
                              errorCodeHelper(context, errorInvalidIPAddress) ??
                                  '',
                            );
                          },
                        ),
                        AppButton.text(
                          label: 'Failed: Invalid DNS',
                          onTap: () {
                            showFailedSnackBar(
                              context,
                              errorCodeHelper(
                                      context, errorInvalidPrimaryDNSServer) ??
                                  '',
                            );
                          },
                        ),
                        AppButton.text(
                          label: 'Failed: Invalid MAC address.',
                          onTap: () {
                            showFailedSnackBar(
                              context,
                              errorCodeHelper(
                                      context, errorInvalidMACAddress) ??
                                  '',
                            );
                          },
                        ),
                        AppButton.text(
                          label: 'Failed: Invalid input',
                          onTap: () {
                            showFailedSnackBar(
                              context,
                              errorCodeHelper(context, errorInvalidInput) ?? '',
                            );
                          },
                        ),
                        AppButton.text(
                          label:
                              'Failed: The specified server IP address is not valid.',
                          onTap: () {
                            showFailedSnackBar(
                              context,
                              errorCodeHelper(context, errorInvalidServer) ??
                                  '',
                            );
                          },
                        ),
                        AppButton.text(
                          label: 'Failed: Invalid destination IP address',
                          onTap: () {
                            showFailedSnackBar(
                              context,
                              errorCodeHelper(
                                      context, errorMissingDestination) ??
                                  '',
                            );
                          },
                        ),
                        AppButton.text(
                          label: 'Failed: The rules cannot be created',
                          onTap: () {
                            showFailedSnackBar(
                              context,
                              errorCodeHelper(context, errorRuleOverlap) ?? '',
                            );
                          },
                        ),
                        AppButton.text(
                          label:
                              'Failed: Guest network names must be different',
                          onTap: () {
                            showFailedSnackBar(
                              context,
                              errorCodeHelper(
                                      context, errorGuestSSIDConflict) ??
                                  '',
                            );
                          },
                        ),
                        AppButton.text(
                          label: 'Failed: Unknown error: _ErrorUnexpected',
                          onTap: () {
                            showFailedSnackBar(
                              context,
                              loc(context).unknownErrorCode('errorUnexpected'),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
