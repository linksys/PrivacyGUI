import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/animated_refresh_container.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/models/_models.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/views/_views.dart';

import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_provider.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_state.dart';
import 'package:privacy_gui/page/components/composed/app_list_card.dart';

import 'package:ui_kit_library/ui_kit.dart';

class DDNSSettingsView extends ArgumentsConsumerStatefulView {
  const DDNSSettingsView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<DDNSSettingsView> createState() => _DDNSSettingsViewState();
}

class _DDNSSettingsViewState extends ConsumerState<DDNSSettingsView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ddnsProvider);
    return SingleChildScrollView(
      child: context.isMobileLayout
          ? Column(
              children: [
                _ddnsProvideSelector(state),
                if (state.current.provider is! NoDDNSProviderUIModel)
                  _buildStatusCell(state)
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    width: context.screenWidth >= 992
                        ? context.colWidth(6)
                        : context.colWidth(4),
                    child: _ddnsProvideSelector(state)),
                if (state.current.provider is! NoDDNSProviderUIModel) ...[
                  AppGap.gutter(),
                  SizedBox(
                      width: context.screenWidth >= 992
                          ? context.colWidth(6)
                          : context.colWidth(4),
                      child: _buildStatusCell(state))
                ],
              ],
            ),
    );
  }

  Widget _ddnsProvideSelector(DDNSState state) => AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleMedium(loc(context).selectAProvider),
            AppGap.lg(),
            AppDropdown<String>(
              value: state.current.provider.name,
              items: state.status.supportedProviders,
              itemAsString: (item) {
                if (item == dynDNSProviderName) {
                  return 'dyn.com';
                } else if (item == noIPDNSProviderName) {
                  return 'No-IP.com';
                } else if (item == tzoDNSProviderName) {
                  return 'tzo.com';
                } else if (item == noDNSProviderName) {
                  return loc(context).disabled;
                } else {
                  return item;
                }
              },
              onChanged: (value) {
                if (value == null) return;
                ref.read(ddnsProvider.notifier).setProvider(value);
              },
            ),
            AppGap.lg(),
            _buildDNSForms(state),
          ],
        ),
      );

  Widget _buildDNSForms(DDNSState state) {
    final provider = state.current.provider;
    if (provider is DynDNSProviderUIModel) {
      return _buildDynDNSForm(provider);
    } else if (provider is NoIPDNSProviderUIModel) {
      return _buildNoIPDNSForm(provider);
    } else if (provider is TzoDNSProviderUIModel) {
      return _buildTzoDNSForm(provider);
    } else {
      return const Center();
    }
  }

  Widget _buildDynDNSForm(DynDNSProviderUIModel? settings) {
    return Column(
      children: [
        DynDNSForm(
          onFormChanged: (settings) {
            if (settings != null) {
              ref.read(ddnsProvider.notifier).setProviderSettings(settings);
            }
          },
          value: settings,
        )
      ],
    );
  }

  Widget _buildNoIPDNSForm(NoIPDNSProviderUIModel? settings) {
    return Column(
      children: [
        NoIPDNSForm(
          onFormChanged: (settings) {
            if (settings != null) {
              ref.read(ddnsProvider.notifier).setProviderSettings(settings);
            }
          },
          value: settings,
        ),
      ],
    );
  }

  Widget _buildTzoDNSForm(TzoDNSProviderUIModel? settings) {
    return Column(
      children: [
        TzoDNSForm(
          onFormChanged: (settings) {
            if (settings != null) {
              ref.read(ddnsProvider.notifier).setProviderSettings(settings);
            }
          },
          value: settings,
        )
      ],
    );
  }

  Widget _buildStatusCell(DDNSState state) {
    return AppCard(
      child: state.current.provider.name == noDNSProviderName
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
                            icon: Icon(AppFontIcons.refresh),
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
                AppGap.xxl(),
                AppListCard.settingNoBorder(
                  padding: EdgeInsets.zero,
                  title: loc(context).internetIPAddress,
                  description: state.status.ipAddress,
                ),
                AppGap.xxl(),
                AppListCard.settingNoBorder(
                  padding: EdgeInsets.zero,
                  title: loc(context).status,
                  description: state.status.status,
                ),
              ],
            ),
    );
  }
}
