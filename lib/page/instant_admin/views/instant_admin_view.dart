import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_settings.dart';
import 'package:privacy_gui/core/data/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/data/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/data/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/instant_admin/providers/_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/timezone.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';
import 'package:ui_kit_library/ui_kit.dart';

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

    return UiKitPageView.withSliver(
      title: loc(context).instantAdmin,
      child: (context, constraints) => MasonryGridView.count(
        crossAxisCount: MediaQuery.of(context).size.width < 600 ? 1 : 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.lg,
        itemCount: widgets.length,
        itemBuilder: (context, index) => widgets[index],
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
      ),
    );
  }

  Widget _buildPasswordWidget(
    BuildContext context,
    RouterPasswordState routerPasswordState,
  ) {
    return AppCard(
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.xxl,
      ),
      child: Column(
        children: [
          _buildListRow(
            key: const Key('passwordCard'),
            title: loc(context).routerPassword,
            description: AppText.labelLarge(
              '•' * (routerPasswordState.adminPassword.length.clamp(0, 16)),
            ),
            trailing: AppIcon.font(AppFontIcons.edit),
            onTap: () {
              _showRouterPasswordModal(routerPasswordState.hint);
            },
          ),
          const Divider(),
          _buildListRow(
            title: loc(context).routerPasswordHint,
            description: routerPasswordState.hint.isEmpty
                ? AppText.labelLarge(loc(context).setOne)
                : AppText.bodyMedium(routerPasswordState.hint),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoFirmwareWidget(BuildContext context, bool isFwAutoUpdate) {
    return AppCard(
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.xxl,
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: loc(context).autoFirmwareUpdate,
            value: isFwAutoUpdate,
            onChanged: (value) async {
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

  Widget _buildManualFirmwareWidget(
    BuildContext context,
    DashboardManagerState dashboardManagerState,
  ) {
    final firmwareVersion = dashboardManagerState.deviceInfo?.firmwareVersion;
    return _buildListCard(
      title: loc(context).manualFirmwareUpdate,
      description: firmwareVersion ?? '--',
      trailing: Tooltip(
        message: BuildConfig.isRemote()
            ? loc(context).featureUnavailableInRemoteMode
            : '',
        child: AppButton.text(
          label: loc(context).manualUpdate,
          key: const Key('manualUpdateButton'),
          onTap: BuildConfig.isRemote()
              ? null
              : () {
                  context.goNamed(RouteNamed.manualFirmwareUpdate);
                },
        ),
      ),
    );
  }

  Widget _buildTimezoneWidget(
    BuildContext context,
    TimezoneState timezoneState,
  ) {
    return _buildListCard(
      key: const Key('timezoneCard'),
      title: loc(context).timezone,
      description: _getTimezone(timezoneState),
      trailing: AppIcon.font(AppFontIcons.chevronRight),
      onTap: () async {
        final result =
            await context.pushNamed<bool?>(RouteNamed.settingsTimeZone);
        if (result == true) {
          if (!context.mounted) return;
          showSuccessSnackBar(context, loc(context).done);
        }
      },
    );
  }

  Widget _buildTransmitRegionWidget(
    BuildContext context,
    PowerTableState powerTableState,
  ) {
    return _buildListCard(
      title: loc(context).transmitRegion,
      descriptionWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.labelLarge(
              powerTableState.country?.resolveDisplayText(context) ?? ''),
          AppGap.sm(),
          AppText.bodyMedium(
            loc(context).transmitRegionDesc,
            color: Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
      trailing: AppIcon.font(AppFontIcons.chevronRight),
      onTap: () {
        handleTransmitRegionTap(powerTableState);
      },
    );
  }

  /// Composed ListCard replacing AppListCard
  Widget _buildListCard({
    Key? key,
    required String title,
    String? description,
    Widget? descriptionWidget,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return AppCard(
      key: key,
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.xxl,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(title),
                AppGap.xs(),
                if (descriptionWidget != null)
                  descriptionWidget
                else if (description != null)
                  AppText.labelLarge(description),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  /// Composed ListRow for inside card
  Widget _buildListRow({
    Key? key,
    required String title,
    Widget? description,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyMedium(title),
                  if (description != null) ...[
                    AppGap.xs(),
                    description,
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  /// Composed SwitchTile replacing AppSwitchTriggerTile
  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required Future<void> Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Expanded(child: AppText.labelLarge(title)),
        AppSwitch(
          value: value,
          onChanged: (newValue) async {
            await onChanged(newValue);
          },
        ),
      ],
    );
  }

  void handleTransmitRegionTap(PowerTableState state) {
    var selected = state.country;
    showSimpleAppDialog(context, title: loc(context).transmitRegion,
        content: StatefulBuilder(builder: (context, setState) {
      return SizedBox(
          height: 300,
          child: ListView.separated(
              itemBuilder: (context, index) {
                final country = state.supportedCountries[index];
                return ListTile(
                  hoverColor: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.5),
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
                          child: AppIcon.font(AppFontIcons.check))
                      : null,
                  onTap: () {
                    setState(() {
                      selected = country;
                    });
                  },
                );
              },
              separatorBuilder: (context, index) => Divider(),
              itemCount: state.supportedCountries.length));
    }), actions: [
      AppButton.text(
        label: loc(context).cancel,
        onTap: () {
          context.pop();
        },
      ),
      AppButton.text(
        label: loc(context).ok,
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
        }, test: (error) => error is ServiceSideEffectError);
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
    final timezone = timezoneState.status.supportedTimezones.firstWhereOrNull(
        (element) => element.timeZoneID == timezoneState.current.timezoneId);
    return timezone != null
        ? '(${getTimezoneGMT(timezone.description)}) ${getTimeZoneRegionName(context, timezone.timeZoneID)}'
        : '--';
  }

  _showRouterPasswordModal(String? hint) {
    TextEditingController controller = TextEditingController();
    TextEditingController confirmController = TextEditingController();
    TextEditingController hintController = TextEditingController()
      ..text = hint ?? '';

    AppPasswordRule hintNotContainPasswordRule(
            TextEditingController controller) =>
        AppPasswordRule(
            label: loc(context).routerPasswordRuleHintContainPassword,
            validate: ((text) => !hintController.text
                .toLowerCase()
                .contains(text.toLowerCase())));
    bool isPasswordValid = false;
    bool isHintNotContainPassword =
        hintNotContainPasswordRule(controller).validate(controller.text);

    List<AppPasswordRule> rules(TextEditingController confirmController) => [
          AppPasswordRule(
              label: loc(context).routerPasswordRuleTenChars,
              validate: ((text) => LengthRule().validate(text))),
          AppPasswordRule(
              label: loc(context).routerPasswordRuleLowerUpper,
              validate: ((text) => HybridCaseRule().validate(text))),
          AppPasswordRule(
              label: loc(context).routerPasswordRuleOneNumber,
              validate: ((text) => DigitalCheckRule().validate(text))),
          AppPasswordRule(
              label: loc(context).routerPasswordRuleSpecialChar,
              validate: ((text) => SpecialCharCheckRule().validate(text))),
          AppPasswordRule(
              label: loc(context).routerPasswordRuleStartEndWithSpace,
              validate: ((text) => NoSurroundWhitespaceRule().validate(text))),
          AppPasswordRule(
              label: loc(context).routerPasswordRuleConsecutiveChar,
              validate: ((text) => !ConsecutiveCharRule().validate(text))),
          AppPasswordRule(
              label: loc(context).passwordsMustMatch,
              validate: ((text) => confirmController.text == text)),
        ];

    showSubmitAppDialog(
      context,
      scrollable: true,
      useRootNavigator: false,
      title: loc(context).routerPassword,
      contentBuilder: (context, setState, onSubmit) {
        FocusNode hintFocusNode = FocusNode();
        FocusNode confirmFocusNode = FocusNode();
        final passwordRules = rules(confirmController);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppPasswordInput(
              key: const Key('newPasswordField'),
              controller: controller,
              label: loc(context).routerPasswordNew,
              rules: passwordRules,
              onChanged: (value) {
                setState(() {
                  isPasswordValid =
                      !passwordRules.any((r) => !r.validate(controller.text));
                  isHintNotContainPassword =
                      hintNotContainPasswordRule(controller)
                          .validate(controller.text);
                });
              },
              onSubmitted: (_) {
                FocusScope.of(context).requestFocus(confirmFocusNode);
              },
            ),
            AppGap.lg(),
            Focus(
              focusNode: confirmFocusNode,
              child: AppPasswordInput(
                key: const Key('confirmPasswordField'),
                controller: confirmController,
                label: loc(context).retypeRouterPassword,
                onChanged: (value) {
                  setState(() {
                    isPasswordValid =
                        !passwordRules.any((r) => !r.validate(controller.text));
                  });
                },
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(hintFocusNode);
                },
              ),
            ),
            AppGap.xxxl(),
            Focus(
              focusNode: hintFocusNode,
              child: AppTextFormField(
                key: const Key('hintTextField'),
                controller: hintController,
                label: loc(context).routerPasswordHintOptional,
                onChanged: (value) {
                  setState(() {
                    isHintNotContainPassword =
                        hintNotContainPasswordRule(controller)
                            .validate(controller.text);
                  });
                },
              ),
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

  Future _save({String? newPassword, String? hint}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await _routerPasswordNotifier
        .setAdminPasswordWithCredentials(newPassword, hint)
        .then<void>((_) {
      if (!mounted) return;
      _success();
    }).onError((error, stackTrace) {
      if (!mounted) return;
      showFailedSnackBar(context, loc(context).invalidAdminPassword);
    });
  }

  void _success() {
    logger.d('success save');
    showSuccessSnackBar(context, loc(context).passwwordUpdated);
  }
}
