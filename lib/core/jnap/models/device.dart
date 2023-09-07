// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

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
  List<Object?> get props {
    return [
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
  }

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

  bool hasSameInterface(String macAddress) {
    return knownInterfaces
            ?.any((interface) => interface.macAddress == macAddress) ??
        false;
  }

  bool hasConnection(String macAddress) {
    return connections.any((connection) => connection.macAddress == macAddress);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'connections': connections.map((x) => x.toMap()).toList(),
      'properties': properties.map((x) => x.toMap()).toList(),
      'unit': unit.toMap(),
      'deviceID': deviceID,
      'maxAllowedProperties': maxAllowedProperties,
      'model': model.toMap(),
      'isAuthority': isAuthority,
      'lastChangeRevision': lastChangeRevision,
      'friendlyName': friendlyName,
      'knownInterfaces': knownInterfaces?.map((x) => x.toMap()).toList(),
      'knownMACAddresses': knownMACAddresses,
      'nodeType': nodeType,
    };
  }

  factory RouterDevice.fromMap(Map<String, dynamic> map) {
    return RouterDevice(
      connections: List<ConnectionDevice>.from(
        map['connections'].map<ConnectionDevice>(
          (x) => ConnectionDevice.fromMap(x),
        ),
      ),
      properties: List<PropertyDevice>.from(
        map['properties'].map<PropertyDevice>(
          (x) => PropertyDevice.fromMap(x as Map<String, dynamic>),
        ),
      ),
      unit: UnitDevice.fromMap(map['unit'] as Map<String, dynamic>),
      deviceID: map['deviceID'] as String,
      maxAllowedProperties: map['maxAllowedProperties'] as int,
      model: ModelDevice.fromMap(map['model'] as Map<String, dynamic>),
      isAuthority: map['isAuthority'] as bool,
      lastChangeRevision: map['lastChangeRevision'] as int,
      friendlyName:
          map['friendlyName'] != null ? map['friendlyName'] as String : null,
      knownInterfaces: map['knownInterfaces'] != null
          ? List<KnownInterfaceDevice>.from(
              map['knownInterfaces'].map<KnownInterfaceDevice?>(
                (x) => KnownInterfaceDevice.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
      knownMACAddresses: map['knownMACAddresses'] != null
          ? List<String>.from((map['knownMACAddresses'] as List<String>))
          : null,
      nodeType: map['nodeType'] != null ? map['nodeType'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory RouterDevice.fromJson(String source) =>
      RouterDevice.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}

class ConnectionDevice extends Equatable {
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

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'macAddress': macAddress,
      'ipAddress': ipAddress,
      'ipv6Address': ipv6Address,
      'parentDeviceID': parentDeviceID,
      'isGuest': isGuest,
    };
  }

  factory ConnectionDevice.fromMap(Map<String, dynamic> map) {
    return ConnectionDevice(
      macAddress: map['macAddress'] as String,
      ipAddress: map['ipAddress'] != null ? map['ipAddress'] as String : null,
      ipv6Address:
          map['ipv6Address'] != null ? map['ipv6Address'] as String : null,
      parentDeviceID: map['parentDeviceID'] != null
          ? map['parentDeviceID'] as String
          : null,
      isGuest: map['isGuest'] != null ? map['isGuest'] as bool : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ConnectionDevice.fromJson(String source) =>
      ConnectionDevice.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props {
    return [
      macAddress,
      ipAddress,
      ipv6Address,
      parentDeviceID,
      isGuest,
    ];
  }
}

class PropertyDevice extends Equatable {
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

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'value': value,
    };
  }

  factory PropertyDevice.fromMap(Map<String, dynamic> map) {
    return PropertyDevice(
      name: map['name'] as String,
      value: map['value'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory PropertyDevice.fromJson(String source) =>
      PropertyDevice.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [name, value];
}

class UnitDevice extends Equatable {
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

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'serialNumber': serialNumber,
      'firmwareVersion': firmwareVersion,
      'firmwareDate': firmwareDate,
      'operatingSystem': operatingSystem,
    };
  }

  factory UnitDevice.fromMap(Map<String, dynamic> map) {
    return UnitDevice(
      serialNumber:
          map['serialNumber'] != null ? map['serialNumber'] as String : null,
      firmwareVersion: map['firmwareVersion'] != null
          ? map['firmwareVersion'] as String
          : null,
      firmwareDate:
          map['firmwareDate'] != null ? map['firmwareDate'] as String : null,
      operatingSystem: map['operatingSystem'] != null
          ? map['operatingSystem'] as String
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UnitDevice.fromJson(String source) =>
      UnitDevice.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props =>
      [serialNumber, firmwareVersion, firmwareDate, operatingSystem];
}

class ModelDevice extends Equatable {
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

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'deviceType': deviceType,
      'manufacturer': manufacturer,
      'modelNumber': modelNumber,
      'hardwareVersion': hardwareVersion,
      'modelDescription': modelDescription,
    };
  }

  factory ModelDevice.fromMap(Map<String, dynamic> map) {
    return ModelDevice(
      deviceType: map['deviceType'] as String,
      manufacturer:
          map['manufacturer'] != null ? map['manufacturer'] as String : null,
      modelNumber:
          map['modelNumber'] != null ? map['modelNumber'] as String : null,
      hardwareVersion: map['hardwareVersion'] != null
          ? map['hardwareVersion'] as String
          : null,
      modelDescription: map['modelDescription'] != null
          ? map['modelDescription'] as String
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ModelDevice.fromJson(String source) =>
      ModelDevice.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props {
    return [
      deviceType,
      manufacturer,
      modelNumber,
      hardwareVersion,
      modelDescription,
    ];
  }
}

class KnownInterfaceDevice extends Equatable {
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

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'macAddress': macAddress,
      'interfaceType': interfaceType,
      'band': band,
    };
  }

  factory KnownInterfaceDevice.fromMap(Map<String, dynamic> map) {
    return KnownInterfaceDevice(
      macAddress: map['macAddress'] as String,
      interfaceType: map['interfaceType'] as String,
      band: map['band'] != null ? map['band'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory KnownInterfaceDevice.fromJson(String source) =>
      KnownInterfaceDevice.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [macAddress, interfaceType, band];
}
