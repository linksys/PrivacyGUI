import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_state.dart';

final geolocationProvider =
    AsyncNotifierProvider<GeolocationNotifier, GeolocationState>(
        () => GeolocationNotifier());

/// Geolocation notifier.
///
/// TODO: Re-implement geolocation fetching using USP device info
/// when cloud service integration is ready.
class GeolocationNotifier extends AsyncNotifier<GeolocationState> {
  @override
  Future<GeolocationState> build() async {
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
}
