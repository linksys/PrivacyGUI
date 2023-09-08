import 'dart:convert';
import 'package:equatable/equatable.dart';

class RawDevice extends Equatable {
  final List<RawDeviceConnection> connections;
  final List<RawDeviceProperty> properties;
  final RawDeviceUnit unit;
  final String deviceID;
  final int maxAllowedProperties;
  final RawDeviceModel model;
  final bool isAuthority;
  final int lastChangeRevision;
  final String? friendlyName;
  final List<RawDeviceKnownInterface>? knownInterfaces;
  final List<String>? knownMACAddresses;
  final String? nodeType;

  const RawDevice({
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

  RawDevice copyWith({
    List<RawDeviceConnection>? connections,
    List<RawDeviceProperty>? properties,
    RawDeviceUnit? unit,
    String? deviceID,
    int? maxAllowedProperties,
    RawDeviceModel? model,
    bool? isAuthority,
    int? lastChangeRevision,
    String? friendlyName,
    List<RawDeviceKnownInterface>? knownInterfaces,
    List<String>? knownMACAddresses,
    String? nodeType,
  }) {
    return RawDevice(
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

  factory RawDevice.fromMap(Map<String, dynamic> map) {
    return RawDevice(
      connections: List<RawDeviceConnection>.from(
        map['connections'].map<RawDeviceConnection>(
          (x) => RawDeviceConnection.fromMap(x),
        ),
      ),
      properties: List<RawDeviceProperty>.from(
        map['properties'].map<RawDeviceProperty>(
          (x) => RawDeviceProperty.fromMap(x as Map<String, dynamic>),
        ),
      ),
      unit: RawDeviceUnit.fromMap(map['unit'] as Map<String, dynamic>),
      deviceID: map['deviceID'] as String,
      maxAllowedProperties: map['maxAllowedProperties'] as int,
      model: RawDeviceModel.fromMap(map['model'] as Map<String, dynamic>),
      isAuthority: map['isAuthority'] as bool,
      lastChangeRevision: map['lastChangeRevision'] as int,
      friendlyName:
          map['friendlyName'] != null ? map['friendlyName'] as String : null,
      knownInterfaces: map['knownInterfaces'] != null
          ? List<RawDeviceKnownInterface>.from(
              map['knownInterfaces'].map<RawDeviceKnownInterface?>(
                (x) => RawDeviceKnownInterface.fromMap(x as Map<String, dynamic>),
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

  factory RawDevice.fromJson(String source) =>
      RawDevice.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}

class RawDeviceConnection extends Equatable {
  final String macAddress;
  final String? ipAddress;
  final String? ipv6Address;
  final String? parentDeviceID;
  final bool? isGuest;

  const RawDeviceConnection({
    required this.macAddress,
    this.ipAddress,
    this.ipv6Address,
    this.parentDeviceID,
    this.isGuest,
  });

  RawDeviceConnection copyWith({
    String? macAddress,
    String? ipAddress,
    String? ipv6Address,
    String? parentDeviceID,
    bool? isGuest,
  }) {
    return RawDeviceConnection(
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

  factory RawDeviceConnection.fromMap(Map<String, dynamic> map) {
    return RawDeviceConnection(
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

  factory RawDeviceConnection.fromJson(String source) =>
      RawDeviceConnection.fromMap(json.decode(source) as Map<String, dynamic>);

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

class RawDeviceProperty extends Equatable {
  final String name;
  final String value;

  const RawDeviceProperty({
    required this.name,
    required this.value,
  });

  RawDeviceProperty copyWith({
    String? name,
    String? value,
  }) {
    return RawDeviceProperty(
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

  factory RawDeviceProperty.fromMap(Map<String, dynamic> map) {
    return RawDeviceProperty(
      name: map['name'] as String,
      value: map['value'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory RawDeviceProperty.fromJson(String source) =>
      RawDeviceProperty.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [name, value];
}

class RawDeviceUnit extends Equatable {
  final String? serialNumber;
  final String? firmwareVersion;
  final String? firmwareDate;
  final String? operatingSystem;

  const RawDeviceUnit({
    this.serialNumber,
    this.firmwareVersion,
    this.firmwareDate,
    this.operatingSystem,
  });

  RawDeviceUnit copyWith({
    String? serialNumber,
    String? firmwareVersion,
    String? firmwareDate,
    String? operatingSystem,
  }) {
    return RawDeviceUnit(
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

  factory RawDeviceUnit.fromMap(Map<String, dynamic> map) {
    return RawDeviceUnit(
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

  factory RawDeviceUnit.fromJson(String source) =>
      RawDeviceUnit.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props =>
      [serialNumber, firmwareVersion, firmwareDate, operatingSystem];
}

class RawDeviceModel extends Equatable {
  final String deviceType;
  final String? manufacturer;
  final String? modelNumber;
  final String? hardwareVersion;
  final String? modelDescription;

  const RawDeviceModel({
    required this.deviceType,
    this.manufacturer,
    this.modelNumber,
    this.hardwareVersion,
    this.modelDescription,
  });

  RawDeviceModel copyWith({
    String? deviceType,
    String? manufacturer,
    String? modelNumber,
    String? hardwareVersion,
    String? modelDescription,
  }) {
    return RawDeviceModel(
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

  factory RawDeviceModel.fromMap(Map<String, dynamic> map) {
    return RawDeviceModel(
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

  factory RawDeviceModel.fromJson(String source) =>
      RawDeviceModel.fromMap(json.decode(source) as Map<String, dynamic>);

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

class RawDeviceKnownInterface extends Equatable {
  final String macAddress;
  final String interfaceType;
  final String? band;

  const RawDeviceKnownInterface({
    required this.macAddress,
    required this.interfaceType,
    this.band,
  });

  RawDeviceKnownInterface copyWith({
    String? macAddress,
    String? interfaceType,
    String? band,
  }) {
    return RawDeviceKnownInterface(
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

  factory RawDeviceKnownInterface.fromMap(Map<String, dynamic> map) {
    return RawDeviceKnownInterface(
      macAddress: map['macAddress'] as String,
      interfaceType: map['interfaceType'] as String,
      band: map['band'] != null ? map['band'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory RawDeviceKnownInterface.fromJson(String source) =>
      RawDeviceKnownInterface.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [macAddress, interfaceType, band];
}
