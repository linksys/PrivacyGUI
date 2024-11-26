import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/linksys_device_cloud_service.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';

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
      return const GeolocationState(
        name: '',
        city: '',
        region: '',
        country: '',
        regionCode: '',
        countryCode: '',
        continentCode: '',
      );
    }
    final result = await ref
        .read(deviceCloudServiceProvider)
        .getGeolocation(master)
        .onError((error, stackTrace) {
      logger.e('Not able to fetch geolocation!');
      return {};
    });

    final locale = ref.read(appSettingsProvider).locale;
    final localeTag = locale?.toLanguageTag() ?? 'en';
    final name = result['org'] ?? '';
    final city = result['city']?['names']?[localeTag] ??
        result['city']['defaultName'] ??
        '';
    final region = result['region']?['names']?[localeTag] ??
        result['region']?['defaultName'] ??
        '';
    final regionCode = result['regionCode'] ?? '';
    final country = result['country']?['names']?[localeTag] ??
        result['country']?['defaultName'] ??
        '';
    final countryCode = result['countryCode'] ?? '';
    final continentCode = result['continentCode'] ?? '';
    return GeolocationState(
      name: name,
      city: city,
      region: region,
      country: country,
      regionCode: regionCode,
      countryCode: countryCode,
      continentCode: continentCode,
    );
  }
}
