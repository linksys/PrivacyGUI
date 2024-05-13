import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/models/firmware_update_settings.dart';
import 'package:linksys_app/core/jnap/providers/firmware_update_provider.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/administration/network_admin/providers/timezone_provider.dart';
import 'package:linksys_app/page/components/shortcuts/dialogs.dart';
import 'package:linksys_app/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/page/administration/network_admin/providers/_providers.dart';
import 'package:linksys_app/providers/auth/_auth.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/validator_rules/_validator_rules.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/card.dart';
import 'package:linksys_widgets/widgets/card/list_card.dart';
import 'package:linksys_widgets/widgets/input_field/validator_widget.dart';
import 'package:linksys_widgets/widgets/panel/switch_trigger_tile.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class NetworkAdminView extends ArgumentsConsumerStatefulView {
  const NetworkAdminView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<NetworkAdminView> createState() =>
      _RouterPasswordContentViewState();
}

class _RouterPasswordContentViewState extends ConsumerState<NetworkAdminView> {
  late final RouterPasswordNotifier _routerPasswordNotifier;
  late final TimezoneNotifier _timezoneNotifier;
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _routerPasswordNotifier = ref.read(routerPasswordProvider.notifier);
    _timezoneNotifier = ref.read(timezoneProvider.notifier);
    _isLoading = true;
    Future.wait([_routerPasswordNotifier.fetch(), _timezoneNotifier.fetch()])
        .then((_) {
      setState(() {
        _isLoading = false;
      });
    });
    final provider = ref.read(routerPasswordProvider);
    _passwordController.text = provider.adminPassword;
  }

  @override
  void dispose() {
    super.dispose();

    _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routerPasswordState = ref.watch(routerPasswordProvider);
    final timezoneState = ref.watch(timezoneProvider);
    final isFwAutoUpdate = ref.watch(firmwareUpdateProvider
            .select((value) => value.settings.updatePolicy)) ==
        FirmwareUpdateSettings.firmwareUpdatePolicyAuto;
    final loginType = ref.watch(authProvider).value?.loginType;

    return _isLoading
        ? const AppFullScreenSpinner()
        : StyledAppPageView(
            scrollable: true,
            title: loc(context).networkAdmin,
            child: Column(
              children: [
                AppCard(
                  child: Column(children: [
                    AppListCard(
                      padding: EdgeInsets.zero,
                      showBorder: false,
                      title: AppText.bodyLarge(loc(context).routerPassword),
                      description: Theme(
                        data: Theme.of(context).copyWith(
                            inputDecorationTheme: const InputDecorationTheme(
                                isDense: true,
                                contentPadding: EdgeInsets.zero)),
                        child: IntrinsicWidth(
                          child: loginType == LoginType.local
                              ? AppPasswordField(
                                  readOnly: true,
                                  border: InputBorder.none,
                                  controller: _passwordController,
                                  suffixIconConstraints: const BoxConstraints(),
                                )
                              : AppTextField(
                                  readOnly: true,
                                  border: InputBorder.none,
                                  controller: _passwordController
                                    ..text = '**********',
                                  secured: true,
                                  suffixIconConstraints: const BoxConstraints(),
                                ),
                        ),
                      ),
                      trailing: const Icon(LinksysIcons.edit),
                      onTap: () {
                        _showRouterPasswordModal();
                      },
                    ),
                    const Divider(),
                    AppListCard(
                      padding: EdgeInsets.zero,
                      showBorder: false,
                      title: AppText.bodyLarge(loc(context).routerPasswordHint),
                      description: routerPasswordState.hint.isEmpty
                          ? AppTextButton('Set one')
                          : AppText.bodyMedium(routerPasswordState.hint),
                      trailing: loginType == LoginType.local
                          ? const Icon(LinksysIcons.edit)
                          : null,
                      onTap: loginType == LoginType.local
                          ? () {
                              // showSubmitAppDialog(content: Center());
                              _showRouterHintModal(routerPasswordState.hint);
                            }
                          : null,
                    ),
                  ]),
                ),
                AppCard(
                  child: AppSwitchTriggerTile(
                    value: isFwAutoUpdate,
                    title: AppText.labelLarge(loc(context).autoFirmwareUpdate),
                    onChanged: (value) {},
                    event: (value) async {
                      await ref
                          .read(firmwareUpdateProvider.notifier)
                          .setFirmwareUpdatePolicy(value
                              ? FirmwareUpdateSettings.firmwareUpdatePolicyAuto
                              : FirmwareUpdateSettings
                                  .firmwareUpdatePolicyManual);
                    },
                  ),
                ),
                AppListCard(
                  title: AppText.bodyLarge(loc(context).timezone),
                  description: AppText.labelLarge(timezoneState
                      .supportedTimezones
                      .firstWhere((element) =>
                          element.timeZoneID == timezoneState.timezoneId)
                      .description),
                  trailing: const Icon(LinksysIcons.chevronRight),
                  onTap: () {
                    context
                        .pushNamed<bool?>(RouteNamed.settingsTimeZone)
                        .then((result) {
                      if (result == true) {
                        showSuccessSnackBar(context, loc(context).done);
                      }
                    });
                  },
                )
              ],
            ),
          );
  }

  _showRouterPasswordModal() {
    TextEditingController controller = TextEditingController();
    bool isPasswordValid = false;
    showSubmitAppDialog(
      context,
      title: loc(context).routerPassword,
      contentBuilder: (context, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPasswordField.withValidator(
            border: const OutlineInputBorder(),
            validations: [
              Validation(
                  description: loc(context).routerPasswordRuleTenChars,
                  validator: ((text) => LengthRule().validate(text))),
              Validation(
                  description: loc(context).routerPasswordRuleLowerUpper,
                  validator: ((text) => HybridCaseRule().validate(text))),
              Validation(
                  description: loc(context).routerPasswordRuleOneNumber,
                  validator: ((text) => DigitalCheckRule().validate(text))),
              Validation(
                  description: loc(context).routerPasswordRuleSpecialChar,
                  validator: ((text) => SpecialCharCheckRule().validate(text))),
            ],
            controller: controller,
            headerText: loc(context).routerPasswordNew,
            onValidationChanged: (isValid) {
              setState(() {
                isPasswordValid = isValid;
              });
            },
          ),
        ],
      ),
      event: () async {
        await _save(newPassword: controller.text);
      },
      checkPositiveEnabled: () {
        return isPasswordValid;
      },
    );
  }

  _showRouterHintModal(String value) {
    TextEditingController controller = TextEditingController()..text = value;
    bool isValid = value.isNotEmpty;
    showSubmitAppDialog(
      context,
      title: loc(context).routerPasswordHint,
      contentBuilder: (context, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            border: const OutlineInputBorder(),
            controller: controller,
            headerText: loc(context).routerPasswordHint,
            onChanged: (value) {
              setState(() {
                isValid = value.isNotEmpty;
              });
            },
          ),
        ],
      ),
      event: () async {
        await _save(hint: controller.text);
      },
      checkPositiveEnabled: () {
        return isValid;
      },
    );
  }

  Future _save({String? newPassword, String? hint}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await _routerPasswordNotifier
        .setAdminPasswordWithCredentials(newPassword, hint)
        .then<void>((_) {
      _success();
    }).onError((error, stackTrace) {
      showFailedSnackBar(context, loc(context).generalError);
    });
  }

  void _success() {
    logger.d('success save');
    showSuccessSnackBar(context, loc(context).passwwordUpdated);
  }
}
