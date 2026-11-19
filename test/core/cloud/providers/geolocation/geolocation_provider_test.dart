import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/cloud/linksys_device_cloud_service.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_provider.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_state.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/providers/app_settings/app_settings.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';

const _master = LinksysDevice(
  connections: [],
  properties: [],
  unit: RawDeviceUnit(serialNumber: 'SN-MASTER'),
  deviceID: 'device-uuid-master',
  maxAllowedProperties: 10,
  model: RawDeviceModel(deviceType: 'Infrastructure'),
  isAuthority: true,
  lastChangeRevision: 1,
  nodeType: 'Master',
  knownInterfaces: [
    RawDeviceKnownInterface(
      macAddress: 'AA:BB:CC:DD:EE:FF',
      interfaceType: 'Wireless',
    ),
  ],
);

/// What the cloud's geolocation call returns for a master in Taipei.
const _taipei = <String, dynamic>{
  'org': 'Chunghwa Telecom',
  'city': {
    'names': {'en': 'Taipei', 'zh-TW': '臺北'},
    'defaultName': 'Taipei City',
  },
  'region': {
    'names': {'en': 'Taipei', 'zh-TW': '臺北市'},
    'defaultName': 'Taipei Region',
  },
  'regionCode': 'TPE',
  'country': {
    'names': {'en': 'Taiwan', 'zh-TW': '臺灣'},
    'defaultName': 'Taiwan (default)',
  },
  'countryCode': 'TW',
  'continentCode': 'AS',
};

const _nowhere = GeolocationState(
  name: '',
  city: '',
  region: '',
  country: '',
  regionCode: '',
  countryCode: '',
  continentCode: '',
);

/// The device cloud, answering only the geolocation call, and counting it.
class _GeolocationCloud extends Fake implements DeviceCloudService {
  Map<String, dynamic> answer = _taipei;
  Object? failure;
  final List<LinksysDevice> askedFor = [];

  @override
  Future<Map<String, dynamic>> getGeolocation(LinksysDevice master) async {
    askedFor.add(master);
    if (failure != null) throw failure!;
    return answer;
  }
}

class _FixedDevices extends DeviceManagerNotifier {
  _FixedDevices(this.devices);

  final List<LinksysDevice> devices;

  @override
  DeviceManagerState build() => DeviceManagerState(deviceList: devices);
}

class _FixedLocale extends AppSettingsNotifier {
  _FixedLocale(this.locale);

  final Locale? locale;

  @override
  AppSettings build() => AppSettings(locale: locale);
}

void main() {
  late _GeolocationCloud cloud;

  ProviderContainer start({
    List<LinksysDevice> devices = const [_master],
    Locale? locale,
  }) {
    final container = ProviderContainer(overrides: [
      deviceCloudServiceProvider.overrideWithValue(cloud),
      deviceManagerProvider.overrideWith(() => _FixedDevices(devices)),
      appSettingsProvider.overrideWith(() => _FixedLocale(locale)),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => cloud = _GeolocationCloud());

  test('locates the master node, in English by default', () async {
    final container = start();

    final location = await container.read(geolocationProvider.future);

    expect(cloud.askedFor.single.deviceID, 'device-uuid-master');
    expect(
      location,
      const GeolocationState(
        name: 'Chunghwa Telecom',
        city: 'Taipei',
        region: 'Taipei',
        country: 'Taiwan',
        regionCode: 'TPE',
        countryCode: 'TW',
        continentCode: 'AS',
      ),
    );
  });

  test('locates the master, not a child node listed before it', () async {
    const child = LinksysDevice(
      connections: [],
      properties: [],
      unit: RawDeviceUnit(serialNumber: 'SN-CHILD'),
      deviceID: 'device-uuid-child',
      maxAllowedProperties: 10,
      model: RawDeviceModel(deviceType: 'Infrastructure'),
      isAuthority: false,
      lastChangeRevision: 1,
      nodeType: 'Slave',
    );
    final container = start(devices: const [child, _master]);

    await container.read(geolocationProvider.future);

    expect(cloud.askedFor.single.deviceID, 'device-uuid-master');
  });

  test('names the place in the app language', () async {
    final container = start(locale: const Locale('zh', 'TW'));

    final location = await container.read(geolocationProvider.future);

    expect(location.city, '臺北');
    expect(location.region, '臺北市');
    expect(location.country, '臺灣');
  });

  test('falls back to the default names for a language the cloud lacks',
      () async {
    final container = start(locale: const Locale('ja'));

    final location = await container.read(geolocationProvider.future);

    expect(location.city, 'Taipei City');
    expect(location.region, 'Taipei Region');
    expect(location.country, 'Taiwan (default)');
  });

  test('is nowhere, without asking the cloud, when there is no master',
      () async {
    final container = start(devices: const []);

    expect(await container.read(geolocationProvider.future), _nowhere);
    expect(cloud.askedFor, isEmpty);
  });

  test('is nowhere when the cloud cannot locate the master', () async {
    cloud.failure = Exception('DEVICE_NOT_FOUND');
    final container = start();

    expect(await container.read(geolocationProvider.future), _nowhere);
  });

  test('leaves out what the cloud does not report', () async {
    cloud.answer = {'countryCode': 'TW'};
    final container = start();

    final location = await container.read(geolocationProvider.future);

    expect(location.countryCode, 'TW');
    expect(location.city, '');
    expect(location.name, '');
  });
}
