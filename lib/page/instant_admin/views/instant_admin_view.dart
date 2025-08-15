import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_settings.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/instant_admin/providers/_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/timezone.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/validator_widget.dart';
import 'package:privacygui_widgets/widgets/panel/switch_trigger_tile.dart';

class InstantAdminView extends ArgumentsConsumerStatefulView {
  const InstantAdminView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<InstantAdminView> createState() => _InstantAdminViewState();
}

class _InstantAdminViewState extends ConsumerState<InstantAdminView> {
  late final RouterPasswordNotifier _routerPasswordNotifier;
  late final TimezoneNotifier _timezoneNotifier;
  late final PowerTableNotifier _powerTableNotifier;

  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _routerPasswordNotifier = ref.read(routerPasswordProvider.notifier);
    _timezoneNotifier = ref.read(timezoneProvider.notifier);
    _powerTableNotifier = ref.read(powerTableProvider.notifier);
    doSomethingWithSpinner(
      context,
      Future.wait([_routerPasswordNotifier.fetch(), _timezoneNotifier.fetch()])
          .then(
        (_) {
          if (!mounted) return;
          final provider = ref.read(routerPasswordProvider);
          _passwordController.text = provider.adminPassword;
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();

    _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routerPasswordState = ref.watch(routerPasswordProvider);
    final isFwAutoUpdate = ref.watch(firmwareUpdateProvider
            .select((value) => value.settings.updatePolicy)) ==
        FirmwareUpdateSettings.firmwareUpdatePolicyAuto;
    final dashboardManagerState = ref.watch(dashboardManagerProvider);
    final timezoneState = ref.watch(timezoneProvider);
    final powerTableState = ref.watch(powerTableProvider);

    final widgets = [
      _buildPasswordWidget(context, routerPasswordState),
      _buildAutoFirmwareWidget(context, isFwAutoUpdate),
      if (dashboardManagerState.skuModelNumber?.endsWith('AH') != true)
        _buildManualFirmwareWidget(context, dashboardManagerState),
      _buildTimezoneWidget(context, timezoneState),
      if (powerTableState.isPowerTableSelectable)
        _buildTransmitRegionWidget(context, powerTableState),
    ];

    return StyledAppPageView(
      title: loc(context).instantAdmin,
      scrollable: true,
      child: (context, constraints) => SizedBox(
        height: constraints.maxHeight,
        child: MasonryGridView.count(
          controller: Scrollable.maybeOf(context)?.widget.controller,
          crossAxisCount: ResponsiveLayout.isMobileLayout(context) ? 1 : 2,
          mainAxisSpacing: Spacing.small2,
          crossAxisSpacing: ResponsiveLayout.columnPadding(context),
          itemCount: widgets.length,
          itemBuilder: (context, index) => widgets[index],
        ),
      ),
    );
  }

  AppCard _buildPasswordWidget(
    BuildContext context,
    RouterPasswordState routerPasswordState,
  ) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.medium,
        horizontal: Spacing.large2,
      ),
      child: Column(
        children: [
          AppListCard(
            key: const Key('passwordCard'),
            padding: EdgeInsets.zero,
            showBorder: false,
            title: AppText.bodyMedium(loc(context).routerPassword),
            description: Theme(
              data: Theme.of(context).copyWith(
                  inputDecorationTheme: const InputDecorationTheme(
                      isDense: true, contentPadding: EdgeInsets.zero)),
              child: IntrinsicWidth(
                  child: Semantics(
                textField: false,
                explicitChildNodes: true,
                child: AppPasswordField(
                  semanticLabel: 'admin Password',
                  readOnly: true,
                  border: InputBorder.none,
                  controller: _passwordController
                    ..text = routerPasswordState.adminPassword,
                  suffixIconConstraints: const BoxConstraints(),
                ),
              )),
            ),
            trailing: const Icon(
              LinksysIcons.edit,
              semanticLabel: 'edit',
            ),
            onTap: () {
              _showRouterPasswordModal(routerPasswordState.hint);
            },
          ),
          const Divider(),
          AppListCard(
            padding: EdgeInsets.zero,
            showBorder: false,
            title: AppText.bodySmall(loc(context).routerPasswordHint),
            description: routerPasswordState.hint.isEmpty
                ? AppText.labelLarge(loc(context).setOne)
                : AppText.bodyMedium(routerPasswordState.hint),
          ),
        ],
      ),
    );
  }

  AppCard _buildAutoFirmwareWidget(BuildContext context, bool isFwAutoUpdate) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.medium,
        horizontal: Spacing.large2,
      ),
      child: Column(
        children: [
          AppSwitchTriggerTile(
            value: isFwAutoUpdate,
            title: AppText.labelLarge(loc(context).autoFirmwareUpdate),
            semanticLabel: 'auto firmware update',
            onChanged: (value) {},
            event: (value) async {
              await ref
                  .read(firmwareUpdateProvider.notifier)
                  .setFirmwareUpdatePolicy(value
                      ? FirmwareUpdateSettings.firmwareUpdatePolicyAuto
                      : FirmwareUpdateSettings.firmwareUpdatePolicyManual);
            },
          ),
        ],
      ),
    );
  }

  AppListCard _buildManualFirmwareWidget(
    BuildContext context,
    DashboardManagerState dashboardManagerState,
  ) {
    final firmwareVersion = dashboardManagerState.deviceInfo?.firmwareVersion;
    return AppListCard(
      title: AppText.bodyMedium(loc(context).manualFirmwareUpdate),
      description: AppText.labelLarge(firmwareVersion ?? '--'),
      trailing: AppTextButton.noPadding(
        loc(context).manualUpdate,
        key: const Key('manualUpdateButton'),
        onTap: () {
          context.goNamed(RouteNamed.manualFirmwareUpdate);
        },
      ),
    );
  }

  AppListCard _buildTimezoneWidget(
    BuildContext context,
    TimezoneState timezoneState,
  ) {
    return AppListCard(
      key: const Key('timezoneCard'),
      title: AppText.bodyLarge(loc(context).timezone),
      description: AppText.labelLarge(_getTimezone(timezoneState)),
      trailing: const Icon(LinksysIcons.chevronRight),
      onTap: () async {
        final result =
            await context.pushNamed<bool?>(RouteNamed.settingsTimeZone);
        if (result == true) {
          if (!mounted) return;
          showSuccessSnackBar(context, loc(context).done);
        }
      },
    );
  }

  AppListCard _buildTransmitRegionWidget(
    BuildContext context,
    PowerTableState powerTableState,
  ) {
    return AppListCard(
      title: AppText.bodyLarge(loc(context).transmitRegion),
      description: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.labelLarge(
              powerTableState.country?.resolveDisplayText(context) ?? ''),
          const AppGap.small2(),
          AppText.bodyMedium(
            loc(context).transmitRegionDesc,
            color: Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
      trailing: const Icon(LinksysIcons.chevronRight),
      onTap: () {
        handleTransmitRegionTap(powerTableState);
      },
    );
  }

  void handleTransmitRegionTap(PowerTableState state) {
    var selected = state.country;
    showSimpleAppDialog(context,
        content: StatefulBuilder(builder: (context, setState) {
      return ListView.separated(
          itemBuilder: (context, index) {
            final country = state.supportedCountries[index];
            return ListTile(
              hoverColor:
                  Theme.of(context).colorScheme.background.withOpacity(.5),
              title: Semantics(
                identifier: 'now-locale-item-${country.name}',
                child: AppText.labelLarge(
                  country.resolveDisplayText(context),
                ),
              ),
              trailing: selected == country
                  ? Semantics(
                      identifier: 'now-country-item-checked',
                      label: 'checked',
                      child: const Icon(LinksysIcons.check))
                  : null,
              onTap: () {
                setState(() {
                  selected = country;
                });
              },
            );
          },
          separatorBuilder: (context, index) => Divider(),
          itemCount: state.supportedCountries.length);
    }), actions: [
      AppTextButton(
        loc(context).cancel,
        onTap: () {
          context.pop();
        },
      ),
      AppTextButton(
        loc(context).ok,
        onTap: () {
          context.pop(selected);
        },
      ),
    ]).then((value) {
      if (value != null && value is PowerTableCountries) {
        onSave(_powerTableNotifier.save(value)).then((_) {
          showSavedSuccessSnackbar();
        }).onError((_, __) {
          showSavedFailSnackbar();
        }).catchError((error) {
          showRouterNotFound();
        }, test: (error) => error is JNAPSideEffectError);
        ;
      }
    });
  }

  Future<T?> onSave<T>(Future<T> task) {
    return doSomethingWithSpinner(context, task);
  }

  void showRouterNotFound() {
    showRouterNotFoundAlert(context, ref);
  }

  void showSavedSuccessSnackbar() {
    showSuccessSnackBar(context, loc(context).saved);
  }

  void showSavedFailSnackbar() {
    showFailedSnackBar(context, loc(context).failedExclamation);
  }

  String _getTimezone(TimezoneState timezoneState) {
    final timezone = timezoneState.supportedTimezones.firstWhereOrNull(
        (element) => element.timeZoneID == timezoneState.timezoneId);
    return timezone != null
        ? '(${getTimezoneGMT(timezone.description)}) ${getTimeZoneRegionName(context, timezone.timeZoneID)}'
        : '--';
  }

  _showRouterPasswordModal(String? hint) {
    TextEditingController controller = TextEditingController();
    TextEditingController confirmController = TextEditingController();
    TextEditingController hintController = TextEditingController()
      ..text = hint ?? '';

    final hintNotContainPasswordValidator = Validation(
        description: loc(context).routerPasswordRuleHintContainPassword,
        validator: ((text) =>
            !hintController.text.toLowerCase().contains(text.toLowerCase())));
    bool isPasswordValid = false;
    bool isHintNotContainPassword =
        hintNotContainPasswordValidator.validator(controller.text);
    final validations = [
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
      Validation(
          description: loc(context).routerPasswordRuleStartEndWithSpace,
          validator: ((text) => NoSurroundWhitespaceRule().validate(text))),
      Validation(
          description: loc(context).routerPasswordRuleConsecutiveChar,
          validator: ((text) => !ConsecutiveCharRule().validate(text))),
      Validation(
          description: loc(context).passwordsMustMatch,
          validator: ((text) => confirmController.text == text)),
    ];
    showSubmitAppDialog(
      context,
      scrollable: true,
      useRootNavigator: false,
      title: loc(context).routerPassword,
      contentBuilder: (context, setState, onSubmit) {
        FocusNode hintFocusNode = FocusNode();
        FocusNode confirmFocusNode = FocusNode();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppPasswordField(
              key: const Key('newPasswordField'),
              border: const OutlineInputBorder(),
              controller: controller,
              headerText: loc(context).routerPasswordNew,
              validations: validations,
              onValidationChanged: (isValid) {
                setState(() {
                  isPasswordValid = isValid;
                });
              },
              onChanged: (value) {
                setState(() {
                  isHintNotContainPassword = hintNotContainPasswordValidator
                      .validator(controller.text);
                });
              },
              onSubmitted: (_) {
                FocusScope.of(context).requestFocus(confirmFocusNode);
              },
            ),
            const AppGap.medium(),
            AppPasswordField(
              key: const Key('confirmPasswordField'),
              border: const OutlineInputBorder(),
              controller: confirmController,
              headerText: loc(context).retypeRouterPassword,
              focusNode: confirmFocusNode,
              onChanged: (value) {
                setState(() {
                  isPasswordValid =
                      !validations.any((v) => !v.validator(controller.text));
                });
              },
              onSubmitted: (_) {
                FocusScope.of(context).requestFocus(hintFocusNode);
              },
            ),
            const AppGap.large2(),
            AppValidatorWidget(
              validations: validations,
              textToValidate: controller.text,
            ),
            const AppGap.large3(),
            AppTextField(
              key: const Key('hintTextField'),
              border: const OutlineInputBorder(),
              controller: hintController,
              headerText: loc(context).routerPasswordHintOptional,
              focusNode: hintFocusNode,
              onChanged: (value) {
                setState(() {
                  isHintNotContainPassword = hintNotContainPasswordValidator
                      .validator(controller.text);
                });
              },
              onSubmitted: (_) {
                if (isPasswordValid && isHintNotContainPassword) {
                  onSubmit();
                }
              },
            ),
            const AppGap.large2(),
            AppValidatorWidget(
              validations: [hintNotContainPasswordValidator],
              textToValidate: controller.text,
            ),
          ],
        );
      },
      event: () async {
        await _save(newPassword: controller.text, hint: hintController.text);
      },
      checkPositiveEnabled: () {
        return isPasswordValid && isHintNotContainPassword;
      },
    );
  }

  Future<void> _scrollToWidget(GlobalKey key) async {
    await Scrollable.ensureVisible(
      key.currentContext!, // Use the GlobalKey's context
      alignment: 0.5, // Adjust alignment as needed (0.0 = top, 1.0 = bottom)
      curve: Curves.easeInOut, // Optional animation curve
    );
  }

  _showRouterHintModal(String value) {
    TextEditingController controller = TextEditingController()..text = value;
    bool isValid = value.isNotEmpty;
    showSubmitAppDialog(
      context,
      title: loc(context).routerPasswordHint,
      contentBuilder: (context, setState, onSubmit) => Column(
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
      showFailedSnackBar(context, loc(context).invalidAdminPassword);
    });
  }

  void _success() {
    logger.d('success save');
    showSuccessSnackBar(context, loc(context).passwwordUpdated);
  }
}
