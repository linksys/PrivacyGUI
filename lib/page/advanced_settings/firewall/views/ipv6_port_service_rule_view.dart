import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/_firewall.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/consts.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/views/widgets/protocol_utils.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/input_field/ipv6_form_field.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class Ipv6PortServiceRuleView extends ArgumentsConsumerStatelessView {
  const Ipv6PortServiceRuleView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Ipv6PortServiceRuleContentView(
      args: super.args,
    );
  }
}

class Ipv6PortServiceRuleContentView extends ArgumentsConsumerStatefulView {
  const Ipv6PortServiceRuleContentView({super.key, super.args});

  @override
  ConsumerState<Ipv6PortServiceRuleContentView> createState() =>
      _AddRuleContentViewState();
}

class _AddRuleContentViewState
    extends ConsumerState<Ipv6PortServiceRuleContentView> {
  late final Ipv6PortServiceRuleNotifier _notifier;

  final TextEditingController _ruleNameController = TextEditingController();
  final TextEditingController _firstExternalPortController =
      TextEditingController();
  final TextEditingController _lastExternalPortController =
      TextEditingController();
  final TextEditingController _ipAddressController = TextEditingController();
  String _protocol = 'Both';
  bool _isEnabled = false;
  List<IPv6FirewallRule> _rules = [];

  @override
  void initState() {
    _notifier = ref.read(ipv6PortServiceRuleProvider.notifier);
    _rules = widget.args['rules'] ?? [];
    final rule = widget.args['edit'] as IPv6FirewallRule?;
    if (rule != null) {
      _notifier.goEdit(_rules, rule).then((_) {
        _ruleNameController.text = rule.description;
        _firstExternalPortController.text =
            '${rule.portRanges.firstOrNull?.firstPort ?? ''}';
        _lastExternalPortController.text =
            '${rule.portRanges.firstOrNull?.lastPort ?? ''}';
        _ipAddressController.text = rule.ipv6Address;
        setState(() {
          _isEnabled = rule.isEnabled;
          _protocol = rule.portRanges.firstOrNull?.protocol ?? 'Both';
        });
      });
    } else {
      _notifier.goAdd(_rules).then((_) {
        setState(() {
          _isEnabled = true;
        });
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();

    _ruleNameController.dispose();
    _firstExternalPortController.dispose();
    _lastExternalPortController.dispose();
    _ipAddressController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ipv6PortServiceRuleProvider);
    return StyledAppPageView(
      scrollable: true,
      title: loc(context).ipv6PortServices,
      bottomBar: PageBottomBar(
        isPositiveEnabled: true,
        isNegitiveEnabled: state.mode == RuleMode.editing ? true : null,
        negitiveLable: loc(context).delete,
        onPositiveTap: () {
          final rule = IPv6FirewallRule(
              isEnabled: _isEnabled,
              portRanges: [
                PortRange(
                  protocol: _protocol,
                  firstPort: int.parse(_firstExternalPortController.text),
                  lastPort: int.parse(_lastExternalPortController.text),
                ),
              ],
              ipv6Address: _ipAddressController.text,
              description: _ruleNameController.text);
          _notifier.save(rule).then((value) {
            if (value) {
              showSuccessSnackBar(
                  context,
                  _notifier.isEdit()
                      ? loc(context).ruleUpdated
                      : loc(context).ruleAdded);

              context.pop(true);
            }
          }).onError((error, stackTrace) {
            logger.e('IpV6 Port service error:',
                error: error, stackTrace: stackTrace);
            showFailedSnackBar(
                context, loc(context).unknownErrorCode(error ?? ''));
          });
        },
        onNegitiveTap: () {
          _notifier.delete().then((value) {
            if (value) {
              showSimpleSnackBar(context, loc(context).ruleDeleted);
            }
            context.pop(true);
          }).onError((error, stackTrace) {
            logger.e('IpV6 Port service error:',
                error: error, stackTrace: stackTrace);
            showFailedSnackBar(
                context, loc(context).unknownErrorCode(error ?? ''));
          });
        },
      ),
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.large2(),
            if (state.mode == RuleMode.editing)
              ..._buildEditContents(state)
            else
              ..._buildAddContents(state)
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAddContents(Ipv6PortServiceRuleState state) {
    return buildInputForms();
  }

  List<Widget> _buildEditContents(Ipv6PortServiceRuleState state) {
    return [
      AppListCard(
        title: AppText.labelLarge(loc(context).ruleEnabled),
        trailing: AppSwitch(
          semanticLabel: 'rule enabled',
          value: _isEnabled,
          onChanged: (value) {
            setState(() {
              _isEnabled = value;
            });
          },
        ),
      ),
      const AppGap.large2(),
      ...buildInputForms(),
    ];
  }

  List<Widget> buildInputForms() {
    return [
      AppTextField.outline(
        headerText: loc(context).ruleName,
        controller: _ruleNameController,
      ),
      const AppGap.large2(),
      AppTextField.minMaxNumber(
        border: const OutlineInputBorder(),
        headerText: loc(context).startPort,
        controller: _firstExternalPortController,
        max: 65535,
      ),
      const AppGap.large2(),
      AppTextField.minMaxNumber(
        border: const OutlineInputBorder(),
        headerText: loc(context).endPort,
        controller: _lastExternalPortController,
        max: 65535,
      ),
      const AppGap.large2(),
      AppText.labelMedium(loc(context).ipAddress),
      const AppGap.medium(),
      AppIPv6FormField(
        semanticLabel: 'ip address',
        controller: _ipAddressController,
        border: const OutlineInputBorder(),
      ),
      const AppGap.large2(),
      AppTextButton(
        loc(context).selectDevices,
        onTap: () async {
          final result = await context.pushNamed<List<DeviceListItem>?>(
              RouteNamed.devicePicker,
              extra: {'type': 'ipv6', 'selectMode': 'single'});

          if (result != null) {
            final device = result.first;
            _ipAddressController.text = device.ipv6Address;
          }
        },
      ),
      const AppGap.large2(),
      AppListCard(
        title: AppText.labelLarge(loc(context).protocol),
        description: AppText.bodyLarge(getProtocolTitle(context, _protocol)),
        trailing: const Icon(LinksysIcons.edit),
        onTap: () async {
          String? protocol = await showSelectProtocolModal(
            context,
            _protocol,
          );
          if (protocol != null) {
            setState(() {
              _protocol = protocol;
            });
          }
        },
      ),
    ];
  }
}
