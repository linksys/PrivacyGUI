import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

class ConnectionModeForm extends ConsumerStatefulWidget {
  const ConnectionModeForm({Key? key}) : super(key: key);

  @override
  ConsumerState<ConnectionModeForm> createState() => _ConnectionModeFormState();
}

class _ConnectionModeFormState extends ConsumerState<ConnectionModeForm> {
  late final TextEditingController _idleTimeController;
  late final TextEditingController _redialPeriodController;

  @override
  void initState() {
    super.initState();
    final ipv4Setting =
        ref.read(internetSettingsProvider).settings.current.ipv4Setting;
    _idleTimeController =
        TextEditingController(text: '${ipv4Setting.maxIdleMinutes ?? 1}');
    _redialPeriodController = TextEditingController(
        text: '${ipv4Setting.reconnectAfterSeconds ?? 20}');
  }

  @override
  void dispose() {
    _idleTimeController.dispose();
    _redialPeriodController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ConnectionModeForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIpv4Setting =
        ref.read(internetSettingsProvider).settings.original.ipv4Setting;
    final newIpv4Setting =
        ref.read(internetSettingsProvider).settings.current.ipv4Setting;

    if (oldIpv4Setting.maxIdleMinutes != newIpv4Setting.maxIdleMinutes) {
      _idleTimeController.text = '${newIpv4Setting.maxIdleMinutes ?? 1}';
    }
    if (oldIpv4Setting.reconnectAfterSeconds !=
        newIpv4Setting.reconnectAfterSeconds) {
      _redialPeriodController.text =
          '${newIpv4Setting.reconnectAfterSeconds ?? 20}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(internetSettingsProvider.notifier);
    final ipv4Setting =
        ref.watch(internetSettingsProvider).settings.current.ipv4Setting;
    final behavior = ipv4Setting.behavior ?? PPPConnectionBehavior.keepAlive;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.titleSmall(loc(context).connectionMode),
          AppGap.lg(),
          AppRadioList(
            selected: behavior,
            items: [
              AppRadioListItem(
                title: loc(context).connectOnDemand,
                value: PPPConnectionBehavior.connectOnDemand,
                expandedWidget: Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: AppMinMaxInput(
                        label:
                            '${loc(context).maxIdleTime} (${loc(context).minutes})',
                        key: const ValueKey('maxIdleTimeText'),
                        max: 9999,
                        min: 1,
                        value: int.tryParse(_idleTimeController.text),
                        onChanged: (value) {
                          _idleTimeController.text = value?.toString() ?? '1';
                          notifier.updateIpv4Settings(ipv4Setting.copyWith(
                            behavior: () =>
                                PPPConnectionBehavior.connectOnDemand,
                            maxIdleMinutes: () => value ?? 1,
                          ));
                        },
                      ),
                    ),
                  ],
                ),
              ),
              AppRadioListItem(
                title: loc(context).keepAlive,
                value: PPPConnectionBehavior.keepAlive,
                expandedWidget: Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: AppMinMaxInput(
                        label:
                            '${loc(context).redialPeriod} (${loc(context).seconds})',
                        key: const ValueKey('redialPeriodText'),
                        max: 180,
                        min: 20,
                        value: int.tryParse(_redialPeriodController.text),
                        onChanged: (value) {
                          _redialPeriodController.text =
                              value?.toString() ?? '20';
                          notifier.updateIpv4Settings(ipv4Setting.copyWith(
                            behavior: () => PPPConnectionBehavior.keepAlive,
                            reconnectAfterSeconds: () => value ?? 20,
                          ));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onChanged: (index, type) {
              if (type == PPPConnectionBehavior.connectOnDemand) {
                notifier.updateIpv4Settings(ipv4Setting.copyWith(
                  behavior: () => PPPConnectionBehavior.connectOnDemand,
                  maxIdleMinutes: () => int.parse(_idleTimeController.text),
                ));
              } else {
                notifier.updateIpv4Settings(ipv4Setting.copyWith(
                  behavior: () => PPPConnectionBehavior.keepAlive,
                  reconnectAfterSeconds: () =>
                      int.parse(_redialPeriodController.text),
                ));
              }
            },
          ),
        ],
      ),
    );
  }
}
