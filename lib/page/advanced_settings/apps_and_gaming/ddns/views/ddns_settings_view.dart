import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/dyn_dns_settings.dart';
import 'package:privacy_gui/core/jnap/models/no_ip_settings.dart';
import 'package:privacy_gui/core/jnap/models/tzo_settings.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/animated_refresh_container.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/views/_views.dart';

import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_provider.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_state.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class DDNSSettingsView extends ArgumentsConsumerStatefulView {
  const DDNSSettingsView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<DDNSSettingsView> createState() => _DDNSSettingsViewState();
}

class _DDNSSettingsViewState extends ConsumerState<DDNSSettingsView> {
  DDNSState? _preserveState;

  @override
  void initState() {
    super.initState();

    doSomethingWithSpinner(
            context, ref.read(ddnsProvider.notifier).fetch(force: true))
        .then((state) {
      setState(() {
        _preserveState = state;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ddnsProvider);
    return StyledAppPageView(
      useMainPadding: false,
      appBarStyle: AppBarStyle.none,
      padding: EdgeInsets.zero,
      scrollable: true,
      title: loc(context).ddns,
      bottomBar: PageBottomBar(
        isPositiveEnabled: _preserveState != state,
        negitiveLable: loc(context).delete,
        onPositiveTap: () {
          doSomethingWithSpinner(
            context,
            ref.read(ddnsProvider.notifier).save(),
          ).then(
            (state) {
              setState(() {
                _preserveState = state;
              });
              showSuccessSnackBar(context, loc(context).saved);
            },
          ).onError((error, stackTrace) {
            showFailedSnackBar(context, loc(context).failedExclamation);
          });
        },
      ),
      child: AppBasicLayout(
        content: ResponsiveLayout(
          desktop: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 6.col, child: _ddnsProvideSelector(state)),
              if (state.provider is! NoDDNSProvider) ...[
                AppGap.gutter(),
                SizedBox(width: 6.col, child: _buildStatusCell(state))
              ],
            ],
          ),
          mobile: Column(
            children: [_ddnsProvideSelector(state)],
          ),
        ),
      ),
    );
  }

  Widget _desktopLayout(DDNSState state) => Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(flex: 1, child: _buildDNSForms(state)),
          Flexible(
              flex: 1,
              child: Align(
                  alignment: Alignment.center,
                  child: Card(
                      child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildStatusCell(state),
                  )))),
        ],
      );
  Widget _mobileLayout(DDNSState state) => Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDNSForms(state),
          _buildStatusCell(state),
        ],
      );

  Widget _ddnsProvideSelector(DDNSState state) => AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleMedium(loc(context).selectAProvider),
            const AppGap.medium(),
            AppDropdownButton<String>(
              initial: state.provider.name,
              items: state.supportedProvider,
              label: (item) {
                if (item == dynDNSProviderName) {
                  return 'dyn.com';
                } else if (item == noIPDNSProviderName) {
                  return 'No-IP.com';
                } else if (item == tzoDNSProviderName) {
                  return 'tzo.com';
                } else {
                  return item;
                }
              },
              onChanged: (value) {
                ref.read(ddnsProvider.notifier).setProvider(value);
              },
            ),
            const AppGap.medium(),
            _buildDNSForms(state),
          ],
        ),
      );
  Widget _buildDNSForms(DDNSState state) {
    final provider = state.provider;
    if (provider is DynDNSProvider) {
      return _buildDynDNSForm(provider.settings);
    } else if (provider is NoIPDNSProvider) {
      return _buildNoIPDNSForm(provider.settings);
    } else if (provider is TzoDNSProvider) {
      return _buildTzoDNSForm(provider.settings);
    } else {
      return const Center();
    }
  }

  Widget _buildDynDNSForm(DynDNSSettings? settings) {
    return Column(
      children: [
        DynDNSForm(
          onFormChanged: (settings) {
            ref.read(ddnsProvider.notifier).setProviderSettings(settings);
          },
          value: settings,
        )
      ],
    );
  }

  Widget _buildNoIPDNSForm(NoIPSettings? settings) {
    return Column(
      children: [
        NoIPDNSForm(
          onFormChanged: (settings) {
            ref.read(ddnsProvider.notifier).setProviderSettings(settings);
          },
          value: settings,
        ),
      ],
    );
  }

  Widget _buildTzoDNSForm(TZOSettings? settings) {
    return Column(
      children: [
        TzoDNSForm(
          onFormChanged: (settings) {
            ref.read(ddnsProvider.notifier).setProviderSettings(settings);
          },
          value: settings,
        )
      ],
    );
  }

  Widget _buildStatusCell(DDNSState state) {
    return AppCard(
      child: state.provider.name == noDNSProviderName
          ? const Center()
          : Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.titleSmall(loc(context).internetConnectionType),
                      AnimatedRefreshContainer(
                        builder: (controller) {
                          return AppIconButton(
                            icon: LinksysIcons.refresh,
                            color: Theme.of(context).colorScheme.primary,
                            onTap: () {
                              controller.repeat();
                              ref
                                  .read(ddnsProvider.notifier)
                                  .getStatus()
                                  .then((value) {
                                controller.stop();
                              });
                            },
                          );
                        },
                      ),
                    ]),
                const AppGap.large2(),
                AppSettingCard.noBorder(
                  padding: EdgeInsets.zero,
                  title: loc(context).internetIPAddress,
                  description: state.ipAddress,
                ),
                const AppGap.large2(),
                AppSettingCard.noBorder(
                  padding: EdgeInsets.zero,
                  title: loc(context).status,
                  description: state.status,
                ),
              ],
            ),
    );
  }
}
