import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Type definition for a provider reader function.
///
/// This allows both [Ref] (from providers) and [WidgetRef] (from widgets)
/// to be used with the same function, since both have a compatible `read` method.
///
/// Example usage:
/// ```dart
/// // In a Provider
/// final ip = getLocalIp(ref.read);
///
/// // In a Widget
/// final ip = getLocalIp(ref.read);
/// ```
typedef ProviderReader = T Function<T>(ProviderListenable<T>);

String getLocalIp(ProviderReader read) =>
    throw UnsupportedError('[Platform ERROR] Get Local IP');

String getFullLocation(ProviderReader read) =>
    throw UnsupportedError('[Platform ERROR] Get Full Location');

/// Browser origin (scheme + host [+ port]), e.g. `https://192.168.1.1`.
/// Empty on non-web, where there is no browser origin and CORS does not apply.
/// Unlike [getLocalIp] (host only), this preserves the scheme for same-origin.
String getCloudOrigin() => '';
