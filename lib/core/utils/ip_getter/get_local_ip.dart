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
