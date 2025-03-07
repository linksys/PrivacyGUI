import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

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
    return StyledAppPageView(
      scrollable: true,
      backState: StyledBackState.none,
      title: 'Snack Bar Sample',
      bottomBar: PageBottomBar(
        isPositiveEnabled: false,
        onPositiveTap: () {},
      ),
      child: (context, constraints, scrollController) => AppBasicLayout(
        content: Column(
          spacing: Spacing.small1,
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              children: [
                AppTextButton(
                  'Success: Saved',
                  onTap: () {
                    showSuccessSnackBar(context, loc(context).saved);
                  },
                ),
                AppTextButton(
                  'Success: Changes saved',
                  onTap: () {
                    showSuccessSnackBar(context, loc(context).changesSaved);
                  },
                ),
                AppTextButton(
                  'Success: Success!',
                  onTap: () {
                    showSuccessSnackBar(
                        context, loc(context).successExclamation);
                  },
                ),
                AppTextButton(
                  'Success: Copied to clipboard!',
                  onTap: () {
                    showSuccessSnackBar(context, loc(context).sharedCopied);
                  },
                ),
                AppTextButton(
                  'Success: Done',
                  onTap: () {
                    showSuccessSnackBar(context, loc(context).done);
                  },
                ),
                AppTextButton(
                  'Success: Router password updated',
                  onTap: () {
                    showSuccessSnackBar(context, loc(context).passwwordUpdated);
                  },
                ),
              ],
            ),
            Column(
              children: [
                AppTextButton(
                  'Failed: Failed!',
                  onTap: () {
                    showFailedSnackBar(
                      context,
                      loc(context).failedExclamation,
                    );
                  },
                ),
                AppTextButton(
                  'Failed: Invalid admin password',
                  onTap: () {
                    showFailedSnackBar(
                      context,
                      loc(context).invalidAdminPassword,
                    );
                  },
                ),
                AppTextButton(
                  'Failed: Invalid firmware file!',
                  onTap: () {
                    showFailedSnackBar(
                      context,
                      loc(context).errorManualUpdateSignatureCheckFailed,
                    );
                  },
                ),
                AppTextButton(
                  'Failed: Error manual update failed!',
                  onTap: () {
                    showFailedSnackBar(
                      context,
                      loc(context).errorManualUpdateFailed,
                    );
                  },
                ),
                AppTextButton(
                  'Failed: IP address or MAC address overlap',
                  onTap: () {
                    showFailedSnackBar(
                      context,
                      loc(context).ipOrMacAddressOverlap,
                    );
                  },
                ),
                AppTextButton(
                  'Failed: Oops, something wrong here! Please try again later',
                  onTap: () {
                    showFailedSnackBar(
                      context,
                      loc(context).generalError,
                    );
                  },
                ),
                AppTextButton(
                  'Failed: Unknown error',
                  onTap: () {
                    showFailedSnackBar(
                      context,
                      loc(context).unknownError,
                    );
                  },
                ),
                AppTextButton(
                  'Failed: Incorrect password',
                  onTap: () {
                    showFailedSnackBar(
                      context,
                      errorCodeHelper(context, errorInvalidPassword) ?? '',
                    );
                  },
                ),
                AppTextButton(
                  'Failed: Too many failed attempts',
                  onTap: () {
                    showFailedSnackBar(
                      context,
                      errorCodeHelper(context, errorAdminAccountLocked) ?? '',
                    );
                  },
                ),
                AppTextButton(
                  'Failed: Invalid destination MAC address',
                  onTap: () {
                    showFailedSnackBar(
                      context,
                      errorCodeHelper(
                              context, errorInvalidDestinationMACAddress) ??
                          '',
                    );
                  },
                ),
                AppTextButton(
                  'Failed: Invalid destination IP address',
                  onTap: () {
                    showFailedSnackBar(
                      context,
                      errorCodeHelper(
                              context, errorInvalidDestinationIpAddress) ??
                          '',
                    );
                  },
                ),
                AppTextButton(
                  'Failed: Invalid gateway IP address',
                  onTap: () {
                    showFailedSnackBar(
                      context,
                      errorCodeHelper(context, errorInvalidGateway) ?? '',
                    );
                  },
                ),
                AppTextButton(
                  'Failed: Invalid IP address',
                  onTap: () {
                    showFailedSnackBar(
                      context,
                      errorCodeHelper(context, errorInvalidIPAddress) ?? '',
                    );
                  },
                ),
                AppTextButton(
                  'Failed: Invalid DNS',
                  onTap: () {
                    showFailedSnackBar(
                      context,
                      errorCodeHelper(context, errorInvalidPrimaryDNSServer) ??
                          '',
                    );
                  },
                ),
                AppTextButton(
                  'Failed: Invalid MAC address.',
                  onTap: () {
                    showFailedSnackBar(
                      context,
                      errorCodeHelper(context, errorInvalidMACAddress) ?? '',
                    );
                  },
                ),
                AppTextButton(
                  'Failed: Invalid input',
                  onTap: () {
                    showFailedSnackBar(
                      context,
                      errorCodeHelper(context, errorInvalidInput) ?? '',
                    );
                  },
                ),
                AppTextButton(
                  'Failed: The specified server IP address is not valid.',
                  onTap: () {
                    showFailedSnackBar(
                      context,
                      errorCodeHelper(context, errorInvalidServer) ?? '',
                    );
                  },
                ),
                AppTextButton(
                  'Failed: Invalid destination IP address',
                  onTap: () {
                    showFailedSnackBar(
                      context,
                      errorCodeHelper(context, errorMissingDestination) ?? '',
                    );
                  },
                ),
                AppTextButton(
                  'Failed: The rules cannot be created',
                  onTap: () {
                    showFailedSnackBar(
                      context,
                      errorCodeHelper(context, errorRuleOverlap) ?? '',
                    );
                  },
                ),
                AppTextButton(
                  'Failed: Guest network names must be different',
                  onTap: () {
                    showFailedSnackBar(
                      context,
                      errorCodeHelper(context, errorGuestSSIDConflict) ?? '',
                    );
                  },
                ),
                AppTextButton(
                  'Failed: Unknown error: _ErrorUnexpected',
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
    );
  }
}