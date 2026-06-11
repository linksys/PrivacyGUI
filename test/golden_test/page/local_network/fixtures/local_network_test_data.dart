import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/local_network/models/local_network_feature_state.dart';
import 'package:privacy_gui/page/local_network/models/local_network_settings.dart';
import 'package:privacy_gui/page/local_network/models/local_network_status.dart';
import 'package:privacy_gui/page/local_network/models/local_network_ui_model.dart';

const dhcpEnabledModel = LocalNetworkUIModel(
  hostName: 'LinksysRouter',
  ipAddress: '192.168.1.1',
  subnetMask: '255.255.255.0',
  dhcpEnabled: true,
  minAddress: '192.168.1.100',
  maxAddress: '192.168.1.200',
  leaseTimeMinutes: 1440,
  dnsServer1: '8.8.8.8',
  dnsServer2: '8.8.4.4',
  dnsServer3: '',
);

const dhcpDisabledModel = LocalNetworkUIModel(
  hostName: 'LinksysRouter',
  ipAddress: '192.168.1.1',
  subnetMask: '255.255.255.0',
  dhcpEnabled: false,
  minAddress: '',
  maxAddress: '',
  leaseTimeMinutes: 0,
  dnsServer1: '',
  dnsServer2: '',
  dnsServer3: '',
);

const dirtyModel = LocalNetworkUIModel(
  hostName: 'MyRouter',
  ipAddress: '192.168.2.1',
  subnetMask: '255.255.255.0',
  dhcpEnabled: true,
  minAddress: '192.168.2.100',
  maxAddress: '192.168.2.200',
  leaseTimeMinutes: 720,
  dnsServer1: '1.1.1.1',
  dnsServer2: '',
  dnsServer3: '',
);

LocalNetworkFeatureState dataState(LocalNetworkUIModel model) {
  final settings = LocalNetworkSettings(model: model);
  return LocalNetworkFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: const LocalNetworkStatus(isLoading: false, lockedOctetCount: 3),
  );
}

LocalNetworkFeatureState dirtyState({bool isSaving = false}) {
  const original = LocalNetworkSettings(model: dhcpEnabledModel);
  const current = LocalNetworkSettings(model: dirtyModel);
  return LocalNetworkFeatureState(
    settings: Preservable(original: original, current: current),
    status: LocalNetworkStatus(
      isLoading: false,
      isSaving: isSaving,
      lockedOctetCount: 3,
    ),
  );
}

LocalNetworkFeatureState get errorState => LocalNetworkFeatureState(
      settings: Preservable(
        original: const LocalNetworkSettings.empty(),
        current: const LocalNetworkSettings.empty(),
      ),
      status: const LocalNetworkStatus(
        isLoading: false,
        errorMessage: 'Connection failed',
      ),
    );

LocalNetworkFeatureState get validationErrorState {
  const settings = LocalNetworkSettings(model: dhcpEnabledModel);
  return LocalNetworkFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: const LocalNetworkStatus(
      isLoading: false,
      lockedOctetCount: 3,
      validationErrors: {
        'ipAddress': 'Invalid IP address',
        'minAddress': 'Start address must be within subnet range',
      },
    ),
  );
}

LocalNetworkFeatureState validationErrorAllState() {
  const model = LocalNetworkUIModel(
    hostName: '',
    ipAddress: '999.999.999.999',
    subnetMask: '0.0.0.0',
    dhcpEnabled: true,
    minAddress: '10.0.0.1',
    maxAddress: '10.0.0.1',
    leaseTimeMinutes: 0,
    dnsServer1: '999.999.999.999',
    dnsServer2: '999.999.999.999',
    dnsServer3: '999.999.999.999',
  );
  const settings = LocalNetworkSettings(model: model);
  return LocalNetworkFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: const LocalNetworkStatus(
      isLoading: false,
      lockedOctetCount: 3,
      validationErrors: {
        'hostName': 'Hostname is required',
        'ipAddress': 'Invalid IP address',
        'subnetMask': 'Invalid subnet mask',
        'minAddress': 'Not in same subnet as router',
        'maxAddress': 'Must be after pool start',
        'leaseTime': 'Must be 1–525600 minutes',
        'dnsServer1': 'Invalid DNS address',
        'dnsServer2': 'Invalid DNS address',
        'dnsServer3': 'Invalid DNS address',
      },
    ),
  );
}
