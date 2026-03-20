import 'get_local_ip.dart';

/// Mobile IP getter — returns empty string since USP mode is web-only.
/// TODO: Re-implement if mobile platform support is needed.
String getLocalIp(ProviderReader read) => '';

String getFullLocation(ProviderReader read) =>
    throw UnsupportedError('[Platform ERROR] Get Full Location');
