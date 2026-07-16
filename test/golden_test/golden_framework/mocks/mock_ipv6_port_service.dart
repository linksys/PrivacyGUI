import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_feature_state.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_rule_list.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_status.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';
import 'package:privacy_gui/page/ipv6_port_service/providers/usp_ipv6_port_service_notifier.dart';

class FixedIpv6PortServiceNotifier extends UspIpv6PortServiceNotifier {
  final Ipv6PortServiceFeatureState _fixedState;

  FixedIpv6PortServiceNotifier(this._fixedState);

  @override
  Ipv6PortServiceFeatureState build() => _fixedState;

  @override
  Future<(Ipv6PortServiceRuleList?, Ipv6PortServiceStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async =>
      (null, null);

  @override
  Future<void> performSave() async {}

  @override
  void addRule(Ipv6PortServiceRuleUIModel rule) {}

  @override
  void editRule(int index, Ipv6PortServiceRuleUIModel rule) {}

  @override
  void toggleRule(int index, bool enabled) {}

  @override
  void deleteRule(int index) {}
}

class FixedDevicesDataNotifier extends DevicesDataNotifier {
  @override
  Future<DevicesData> build() async => DevicesData(
        meshNetwork: MeshNetwork(
          master: MasterNode(deviceId: 'GATEWAY', model: 'Test Router'),
        ),
      );
}

List<Override> ipv6PortServiceOverrides(Ipv6PortServiceFeatureState state) => [
      uspIpv6PortServiceProvider.overrideWith(
        () => FixedIpv6PortServiceNotifier(state),
      ),
      devicesDataProvider.overrideWith(() => FixedDevicesDataNotifier()),
    ];
