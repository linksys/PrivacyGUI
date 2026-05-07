/// Connection detail for a WiFi client: band + SSID name.
class ClientConnectionDetail {
  final String band; // "2.4GHz", "5GHz", "6GHz", or ""
  final String ssidName; // The network name

  const ClientConnectionDetail({required this.band, required this.ssidName});
}
