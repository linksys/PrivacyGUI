import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/ddns/models/ddns_feature_state.dart';
import 'package:privacy_gui/page/ddns/models/ddns_rules.dart';
import 'package:privacy_gui/page/ddns/models/ddns_settings.dart';
import 'package:privacy_gui/page/ddns/providers/usp_ddns_notifier.dart';
import 'package:privacy_gui/page/ddns/views/components/ddns_status_card.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The item of the provider dropdown that stands for "Disabled".
///
/// [AppDropdown] needs one non-null value per item, and a provider path is
/// never empty.
const _disabledItem = '';

/// Dynamic DNS page: a provider (or "Disabled"), the account and the host name
/// it updates, and the status of the router's last update.
///
/// 1.x's layout: the provider card, and beside it on wide screens (below on
/// narrow ones) the status card. One set of fields serves every provider,
/// because TR-181 has no provider-specific leaf (1.x's DynDNS mode, wildcard
/// and mail exchange are out of FLWRT's scope, linksys/FWDEV#191).
class UspDdnsView extends ConsumerStatefulWidget {
  const UspDdnsView({super.key});

  @override
  ConsumerState<UspDdnsView> createState() => _UspDdnsViewState();
}

class _UspDdnsViewState extends ConsumerState<UspDdnsView> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _hostnameController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _hostnameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    for (final (focus, field) in [
      (_usernameFocus, DdnsField.username),
      (_passwordFocus, DdnsField.password),
      (_hostnameFocus, DdnsField.hostname),
    ]) {
      focus.addListener(() {
        if (!focus.hasFocus) {
          ref.read(uspDdnsProvider.notifier).validateField(field);
        }
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _hostnameController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _hostnameFocus.dispose();
    super.dispose();
  }

  /// Puts the fields on the settings when they arrive or change from outside
  /// the fields: the first read, a revert, and the read after a save (which
  /// empties the password, as the router never reads it back).
  void _syncControllers(DdnsSettings settings) {
    void sync(TextEditingController controller, String value) {
      if (controller.text != value) controller.text = value;
    }

    sync(_usernameController, settings.username);
    sync(_passwordController, settings.password);
    sync(_hostnameController, settings.hostname);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(uspDdnsProvider);
    final status = state.status;

    return UiKitPageView.withSliver(
      scrollable: true,
      title: loc(context).ddns,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspAdvancedSettings,
      onRefresh: () =>
          ref.read(uspDdnsProvider.notifier).fetch(forceRemote: true),
      bottomBar: _buildBottomBar(context, state),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        if (status.isLoading) {
          return const Center(child: AppLoader());
        }
        if (status.error != null) {
          return ServiceErrorView(
            error: status.error,
            title: loc(context).failedToLoadSettings,
            onRetry: () =>
                ref.read(uspDdnsProvider.notifier).fetch(forceRemote: true),
          );
        }
        _syncControllers(state.settings.current);
        return _buildContent(context, state);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Bar
  // ---------------------------------------------------------------------------

  UiKitBottomBarConfig _buildBottomBar(
    BuildContext context,
    DdnsFeatureState state,
  ) {
    // Always return a config to keep the widget tree stable: returning null
    // when clean changes the tree, which takes a TextField's focus on Web.
    return UiKitBottomBarConfig(
      positiveLabel: loc(context).save,
      isPositiveEnabled: state.canSave,
      isNegativeEnabled: state.isDirty,
      onPositiveTap: state.canSave ? () => _onSave(context) : null,
      onNegativeTap: state.isDirty
          ? () => ref.read(uspDdnsProvider.notifier).revert()
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Content
  // ---------------------------------------------------------------------------

  Widget _buildContent(BuildContext context, DdnsFeatureState state) {
    final providerCard = _buildProviderCard(context, state);
    const statusCard = DdnsStatusCard();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(
          loc(context).ddnsPageDesc,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        AppGap.xl(),
        AppResponsiveLayout(
          mobile: (_) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [providerCard, AppGap.md(), statusCard],
          ),
          desktop: (_) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: providerCard),
              AppGap.gutter(),
              const Expanded(child: statusCard),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProviderCard(BuildContext context, DdnsFeatureState state) {
    final notifier = ref.read(uspDdnsProvider.notifier);
    final settings = state.settings.current;
    final errors = state.status.fieldErrors;
    final saving = state.status.isSaving;
    final l = loc(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleSmall(l.selectAProvider),
          AppGap.md(),
          AppDropdown<String>(
            identifier: 'ddns-provider',
            itemIdentifier: (item) =>
                'ddns-provider-${_itemKey(settings, item)}',
            items: [
              _disabledItem,
              for (final provider in settings.providers) provider.path,
            ],
            value: settings.providerPath ?? _disabledItem,
            itemAsString: (item) => item == _disabledItem
                ? l.disabled
                : settings.providers.firstWhere((p) => p.path == item).name,
            onChanged: saving
                ? null
                : (item) => notifier.selectProvider(
                    item == null || item == _disabledItem ? null : item),
          ),
          if (settings.isEnabled) ...[
            AppGap.lg(),
            AppTextFormField(
              controller: _usernameController,
              focusNode: _usernameFocus,
              identifier: 'ddns-username',
              label: l.username,
              errorDisplayMode: AppErrorDisplayMode.text,
              externalErrorText: errors.contains(DdnsField.username)
                  ? l.invalidUsername
                  : null,
              onChanged: (v) =>
                  notifier.updateSetting((s) => s.copyWith(username: v)),
            ),
            AppGap.md(),
            AppPasswordInput(
              controller: _passwordController,
              focusNode: _passwordFocus,
              identifier: 'ddns-password',
              label: l.password,
              // The router keeps its password secret, so the field starts
              // empty; with an account stored, empty keeps it.
              hintText:
                  settings.hasStoredAccount ? l.ddnsPasswordKeepHint : null,
              errorText: errors.contains(DdnsField.password)
                  ? l.invalidPassword
                  : null,
              onChanged: (v) =>
                  notifier.updateSetting((s) => s.copyWith(password: v)),
            ),
            AppGap.md(),
            AppTextFormField(
              controller: _hostnameController,
              focusNode: _hostnameFocus,
              identifier: 'ddns-hostname',
              label: l.hostName,
              errorDisplayMode: AppErrorDisplayMode.text,
              externalErrorText: errors.contains(DdnsField.hostname)
                  ? l.invalidHostname
                  : null,
              onChanged: (v) =>
                  notifier.updateSetting((s) => s.copyWith(hostname: v)),
            ),
          ],
        ],
      ),
    );
  }

  /// The E2E key of a dropdown item: `disabled`, or the provider's
  /// data-derived key.
  static String _itemKey(DdnsSettings settings, String item) =>
      item == _disabledItem
          ? 'disabled'
          : settings.providers.firstWhere((p) => p.path == item).identifierKey;

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _onSave(BuildContext context) async {
    // Save is enabled only when every field passes, so this clears an error
    // still shown for a field that was corrected without losing focus.
    ref.read(uspDdnsProvider.notifier).validate();
    try {
      await doSomethingWithSpinner(
        context,
        ref.read(uspDdnsProvider.notifier).save(),
      );
      if (context.mounted) {
        showSuccessSnackBar(context, loc(context).changesSaved);
      }
    } catch (e) {
      if (context.mounted) {
        showSaveErrorSnackBar(context, e);
      }
    }
  }
}
