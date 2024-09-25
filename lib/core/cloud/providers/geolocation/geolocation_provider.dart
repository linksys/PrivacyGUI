import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/linksys_device_cloud_service.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';

final geolocationProvider =
    AsyncNotifierProvider<GeolocationNotifier, GeolocationState>(
        () => GeolocationNotifier());

class GeolocationNotifier extends AsyncNotifier<GeolocationState> {
  @override
  Future<GeolocationState> build() {
    final master = ref
        .watch(deviceManagerProvider)
        .nodeDevices
        .firstWhereOrNull((element) => element.nodeType == 'Master');
    return fetch(master);
  }

  Future<GeolocationState> fetch(LinksysDevice? master) async {
    if (master == null) {
      return const GeolocationState(name: '', region: '', countryCode: '');
    }
    final result =
        await ref.read(deviceCloudServiceProvider).getGeolocation(master);
    final name = result['org'] ?? '';
    final region = result['region'] ?? '';
    final countryCode = result['countryCode'] ?? '';
    return GeolocationState(
        name: name, region: region, countryCode: countryCode);
  }
}
