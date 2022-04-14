class Device {
  const Device({required this.address, required this.port});

  final String address;
  final String port;

  Map toJson() => {
        'address': address,
        'port': port,
      };

  static Device fromJson(Map<String, dynamic> json) {
    return Device(
        address: json['address'].toString(), port: json['port'].toString());
  }
}
