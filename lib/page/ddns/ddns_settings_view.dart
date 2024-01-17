import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/models/dyn_dns_settings.dart';
import 'package:linksys_app/core/jnap/models/no_ip_settings.dart';
import 'package:linksys_app/core/jnap/models/tzo_settings.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/ddns/dyn_ddns_form.dart';
import 'package:linksys_app/page/ddns/no_ip_ddns_form.dart';
import 'package:linksys_app/page/ddns/tzo_ddns_form%20copy.dart';
import 'package:linksys_app/provider/ddns/ddns_provider.dart';
import 'package:linksys_app/provider/ddns/ddns_state.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';
import 'package:linksys_widgets/widgets/dropdown/dropdown_menu.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class DDNSSettingsView extends ArgumentsConsumerStatefulView {
  const DDNSSettingsView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<DDNSSettingsView> createState() => _DDNSSettingsViewState();
}

class _DDNSSettingsViewState extends ConsumerState<DDNSSettingsView> {
  bool _isLoading = false;
  String _selected = 'disabled';
  DynDNSSettings? _dynDNSSettings;
  NoIPSettings? _noIPSettings;
  TZOSettings? _tzoSettings;

  @override
  void initState() {
    super.initState();
    setState(() {
      _isLoading = true;
    });
    ref.read(ddnsProvider.notifier).fetch(force: true).then((value) {
      final provider = ref.read(ddnsProvider).provider;
      setState(() {
        _selected = provider.name;
        if (provider is DynDNSProvider) {
          _dynDNSSettings = provider.settings;
        } else if (provider is NoIPDNSProvider) {
          _noIPSettings = provider.settings;
        } else if (provider is TzoDNSProvider) {
          _tzoSettings = provider.settings;
        }
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ddnsProvider);
    return _isLoading
        ? const AppFullScreenSpinner()
        : StyledAppPageView(
            scrollable: true,
            title: 'DDNS Settings',
            actions: [
              AppTextButton.noPadding(
                'Save',
                onTap: () {
                  ref.read(ddnsProvider.notifier).save(
                        _selected == noDNSProviderName ? 'None' : _selected,
                        dynDNSSettings: _selected == dynDNSProviderName
                            ? _dynDNSSettings
                            : null,
                        noIPSettings: _selected == noIPDNSProviderName
                            ? _noIPSettings
                            : null,
                        tzoSettings: _selected == tzoDNSProviderName
                            ? _tzoSettings
                            : null,
                      );
                },
              )
            ],
            child: AppBasicLayout(
              content: Column(
                children: [
                  _ddnsProvideSelector(state),
                  ResponsiveLayout(
                    desktop: _desktopLayout(state),
                    mobile: _mobileLayout(state),
                  ),
                ],
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

  Widget _ddnsProvideSelector(DDNSState state) => Row(
        children: [
          const AppText.headlineSmall('Select a provider:'),
          const AppGap.regular(),
          AppDropdownMenu<String>(
            initial: _selected,
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
              setState(() {
                _selected = value;
              });
            },
          ),
        ],
      );
  Widget _buildDNSForms(DDNSState state) {
    if (_selected == noDNSProviderName) {
      return const Center();
    } else if (_selected == dynDNSProviderName) {
      return _buildDynDNSForm(_dynDNSSettings);
    } else if (_selected == noIPDNSProviderName) {
      return _buildNoIPDNSForm(_noIPSettings);
    } else if (_selected == tzoDNSProviderName) {
      return _buildTzoDNSForm(_tzoSettings);
    } else {
      return const Center();
    }
  }

  Widget _buildDynDNSForm(DynDNSSettings? settings) {
    return Column(
      children: [
        DynDNSForm(
          onFormChanged: (settings) {
            _dynDNSSettings = settings;
          },
          initialValue: settings,
        )
      ],
    );
  }

  Widget _buildNoIPDNSForm(NoIPSettings? settings) {
    return Column(
      children: [
        NoIPDNSForm(
          onFormChanged: (settings) {
            _noIPSettings = settings;
          },
          initialValue: settings,
        ),
      ],
    );
  }

  Widget _buildTzoDNSForm(TZOSettings? settings) {
    return Column(
      children: [
        TzoDNSForm(
          onFormChanged: (settings) {
            _tzoSettings = settings;
          },
          initialValue: settings,
        )
      ],
    );
  }

  Widget _buildStatusCell(DDNSState state) {
    return _selected == noDNSProviderName
        ? const Center()
        : Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.labelMedium('Internet IP address: ${state.ipAddress}'),
              const AppGap.regular(),
              AppText.labelMedium('Status: ${state.status}'),
              const AppGap.big(),
              AppFilledButton(
                'Update',
                onTap: () {
                  ref.read(ddnsProvider.notifier).getStatus();
                },
              )
            ],
          );
  }
}

