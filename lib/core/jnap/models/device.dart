import 'package:equatable/equatable.dart';

class RouterDevice extends Equatable {
  final List<ConnectionDevice> connections;
  final List<PropertyDevice> properties;
  final UnitDevice unit;
  final String deviceID;
  final int maxAllowedProperties;
  final ModelDevice model;
  final bool isAuthority;
  final int lastChangeRevision;
  final String? friendlyName;
  final List<KnownInterfaceDevice>? knownInterfaces;
  final List<String>? knownMACAddresses;
  final String? nodeType;

  const RouterDevice({
    required this.connections,
    required this.properties,
    required this.unit,
    required this.deviceID,
    required this.maxAllowedProperties,
    required this.model,
    required this.isAuthority,
    required this.lastChangeRevision,
    this.friendlyName,
    this.knownInterfaces,
    this.knownMACAddresses,
    this.nodeType,
  });

  @override
  List<Object?> get props => [
    connections,
    properties,
    unit,
    deviceID,
    maxAllowedProperties,
    model,
    isAuthority,
    lastChangeRevision,
    friendlyName,
    knownInterfaces,
    knownMACAddresses,
    nodeType,
  ];

  RouterDevice copyWith({
    List<ConnectionDevice>? connections,
    List<PropertyDevice>? properties,
    UnitDevice? unit,
    String? deviceID,
    int? maxAllowedProperties,
    ModelDevice? model,
    bool? isAuthority,
    int? lastChangeRevision,
    String? friendlyName,
    List<KnownInterfaceDevice>? knownInterfaces,
    List<String>? knownMACAddresses,
    String? nodeType,
  }) {
    return RouterDevice(
      connections: connections ?? this.connections,
      properties: properties ?? this.properties,
      unit: unit ?? this.unit,
      deviceID: deviceID ?? this.deviceID,
      maxAllowedProperties: maxAllowedProperties ?? this.maxAllowedProperties,
      model: model ?? this.model,
      isAuthority: isAuthority ?? this.isAuthority,
      lastChangeRevision: lastChangeRevision ?? this.lastChangeRevision,
      friendlyName: friendlyName ?? this.friendlyName,
      knownInterfaces: knownInterfaces ?? this.knownInterfaces,
      knownMACAddresses: knownMACAddresses ?? this.knownMACAddresses,
      nodeType: nodeType ?? this.nodeType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'connections': connections,
      'properties': properties,
      'unit': unit.toJson(),
      'deviceID': deviceID,
      'maxAllowedProperties': maxAllowedProperties,
      'model': model.toJson(),
      'isAuthority': isAuthority,
      'lastChangeRevision': lastChangeRevision,
      'friendlyName': friendlyName,
      'knownInterfaces': knownInterfaces,
      'knownMACAddresses': knownMACAddresses,
      'nodeType': nodeType,
    }..removeWhere((key, value) => value == null);
  }

  factory RouterDevice.fromJson(Map<String, dynamic> json) {
    return RouterDevice(
      connections: List.from(json['connections'])
          .map((e) => ConnectionDevice.fromJson(e))
          .toList(),
      properties: List.from(json['properties'])
          .map((e) => PropertyDevice.fromJson(e))
          .toList(),
      unit: UnitDevice.fromJson(json['unit']),
      deviceID: json['deviceID'],
      maxAllowedProperties: json['maxAllowedProperties'],
      model: ModelDevice.fromJson(json['model']),
      isAuthority: json['isAuthority'],
      lastChangeRevision: json['lastChangeRevision'],
      friendlyName: json['friendlyName'],
      knownInterfaces: (json['knownInterfaces'] != null)
          ? List.from(json['knownInterfaces'])
              .map((e) => KnownInterfaceDevice.fromJson(e))
              .toList()
          : null,
      knownMACAddresses: (json['knownMACAddresses'] != null)
          ? List.from(json['knownMACAddresses'])
          : null,
      nodeType: json['nodeType'],
    );
  }

  bool hasSameInterface(String macAddress) {
    return knownInterfaces
            ?.any((interface) => interface.macAddress == macAddress) ??
        false;
  }

  bool hasConnection(String macAddress) {
    return connections.any((connection) => connection.macAddress == macAddress);
  }
}

class ConnectionDevice {
  final String macAddress;
  final String? ipAddress;
  final String? ipv6Address;
  final String? parentDeviceID;
  final bool? isGuest;

  const ConnectionDevice({
    required this.macAddress,
    this.ipAddress,
    this.ipv6Address,
    this.parentDeviceID,
    this.isGuest,
  });

  factory ConnectionDevice.fromJson(Map<String, dynamic> json) {
    return ConnectionDevice(
      macAddress: json['macAddress'],
      ipAddress: json['ipAddress'],
      ipv6Address: json['ipv6Address'],
      parentDeviceID: json['parentDeviceID'],
      isGuest: json['isGuest'],
    );
  }

  ConnectionDevice copyWith({
    String? macAddress,
    String? ipAddress,
    String? ipv6Address,
    String? parentDeviceID,
    bool? isGuest,
  }) {
    return ConnectionDevice(
      macAddress: macAddress ?? this.macAddress,
      ipAddress: ipAddress ?? this.ipAddress,
      ipv6Address: ipv6Address ?? this.ipv6Address,
      parentDeviceID: parentDeviceID ?? this.parentDeviceID,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}

class PropertyDevice {
  final String name;
  final String value;

  const PropertyDevice({
    required this.name,
    required this.value,
  });

  PropertyDevice copyWith({
    String? name,
    String? value,
  }) {
    return PropertyDevice(
      name: name ?? this.name,
      value: value ?? this.value,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
    };
  }

  factory PropertyDevice.fromJson(Map<String, dynamic> json) {
    return PropertyDevice(
      name: json['name'],
      value: json['value'],
    );
  }
}

class UnitDevice {
  final String? serialNumber;
  final String? firmwareVersion;
  final String? firmwareDate;
  final String? operatingSystem;

  const UnitDevice({
    this.serialNumber,
    this.firmwareVersion,
    this.firmwareDate,
    this.operatingSystem,
  });

  UnitDevice copyWith({
    String? serialNumber,
    String? firmwareVersion,
    String? firmwareDate,
    String? operatingSystem,
  }) {
    return UnitDevice(
      serialNumber: serialNumber ?? this.serialNumber,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      firmwareDate: firmwareDate ?? this.firmwareDate,
      operatingSystem: operatingSystem ?? this.operatingSystem,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serialNumber': serialNumber,
      'firmwareVersion': firmwareVersion,
      'firmwareDate': firmwareDate,
      'operatingSystem': operatingSystem,
    };
  }

  factory UnitDevice.fromJson(Map<String, dynamic> json) {
    return UnitDevice(
      serialNumber: json['serialNumber'],
      firmwareVersion: json['firmwareVersion'],
      firmwareDate: json['firmwareDate'],
      operatingSystem: json['operatingSystem'],
    );
  }
}

class ModelDevice {
  final String deviceType;
  final String? manufacturer;
  final String? modelNumber;
  final String? hardwareVersion;
  final String? modelDescription;

  const ModelDevice({
    required this.deviceType,
    this.manufacturer,
    this.modelNumber,
    this.hardwareVersion,
    this.modelDescription,
  });

  ModelDevice copyWith({
    String? deviceType,
    String? manufacturer,
    String? modelNumber,
    String? hardwareVersion,
    String? modelDescription,
  }) {
    return ModelDevice(
      deviceType: deviceType ?? this.deviceType,
      manufacturer: manufacturer ?? this.manufacturer,
      modelNumber: modelNumber ?? this.modelNumber,
      hardwareVersion: hardwareVersion ?? this.hardwareVersion,
      modelDescription: modelDescription ?? this.modelDescription,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceType': deviceType,
      'manufacturer': manufacturer,
      'modelNumber': modelNumber,
      'hardwareVersion': hardwareVersion,
      'modelDescription': modelDescription,
    };
  }

  factory ModelDevice.fromJson(Map<String, dynamic> json) {
    return ModelDevice(
      deviceType: json['deviceType'],
      manufacturer: json['manufacturer'],
      modelNumber: json['modelNumber'],
      hardwareVersion: json['hardwareVersion'],
      modelDescription: json['modelDescription'],
    );
  }
}

class KnownInterfaceDevice {
  final String macAddress;
  final String interfaceType;
  final String? band;

  const KnownInterfaceDevice({
    required this.macAddress,
    required this.interfaceType,
    this.band,
  });

  KnownInterfaceDevice copyWith({
    String? macAddress,
    String? interfaceType,
    String? band,
  }) {
    return KnownInterfaceDevice(
      macAddress: macAddress ?? this.macAddress,
      interfaceType: interfaceType ?? this.interfaceType,
      band: band ?? this.band,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'macAddress': macAddress,
      'interfaceType': interfaceType,
      'band': band,
    };
  }

  factory KnownInterfaceDevice.fromJson(Map<String, dynamic> json) {
    return KnownInterfaceDevice(
      macAddress: json['macAddress'],
      interfaceType: json['interfaceType'],
      band: json['band'],
    );
  }
}
