import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

sealed class ManualUpdateStatus {
  String get value;
  void start(StateSetter setState);
  void stop();

  static ManualUpdateStatus fromMap(Map<String, dynamic> map) => switch (map) {
        {'progress': int progress} => ManualUpdateInstalling(progress),
        _ => ManualUpdateRebooting(),
      };

  Map<String, dynamic> toMap() => {};
}

class ManualUpdateInstalling implements ManualUpdateStatus {
  int progress;
  StreamSubscription? _sub;

  ManualUpdateInstalling(this.progress);

  @override
  void start(StateSetter setState) {
    _sub = Stream.periodic(Duration(seconds: 1), (value) => value * 4)
        .listen((data) {
      setState(() {
        progress = data;
      });
    });
  }

  @override
  void stop() {
    _sub?.cancel();
  }

  ManualUpdateInstalling copyWith(int? progress) =>
      ManualUpdateInstalling(progress ?? this.progress);

  @override
  String get value => '${(progress % 100) / 100.0}'.padRight(2);

  @override
  Map<String, dynamic> toMap() => {'type': 'installing', 'progress': progress};
}

class ManualUpdateRebooting implements ManualUpdateStatus {
  @override
  String get value => throw UnimplementedError();

  @override
  void start(StateSetter setState) {}

  @override
  void stop() {}
   @override
  Map<String, dynamic> toMap() => {'type': 'rebooting'};
}

class FileInfo extends Equatable {
  final String name;
  final Uint8List bytes;
  const FileInfo({
    required this.name,
    required this.bytes,
  });

  FileInfo copyWith({
    String? name,
    Uint8List? bytes,
  }) {
    return FileInfo(
      name: name ?? this.name,
      bytes: bytes ?? this.bytes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bytes': Base64Encoder().convert(bytes),
    };
  }

  factory FileInfo.fromMap(Map<String, dynamic> map) {
    return FileInfo(
      name: map['name'] ?? '',
      bytes: map['bytes'] != null
          ? Base64Decoder().convert(map['bytes'] as String)
          : Uint8List(0),
    );
  }

  String toJson() => json.encode(toMap());

  factory FileInfo.fromJson(String source) =>
      FileInfo.fromMap(json.decode(source));

  @override
  String toString() => 'FileInfo(name: $name, bytes: $bytes)';

  @override
  List<Object> get props => [name, bytes];
}

class ManualFirmwareUpdateState extends Equatable {
  final FileInfo? file;
  final ManualUpdateStatus? status;
  const ManualFirmwareUpdateState({
    this.file,
    this.status,
  });

  ManualFirmwareUpdateState copyWith({
    ValueGetter<FileInfo?>? file,
    ValueGetter<ManualUpdateStatus?>? status,
  }) {
    return ManualFirmwareUpdateState(
      file: file != null ? file() : this.file,
      status: status != null ? status() : this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'file': file?.toMap(),
      'status': status?.toMap(),
    };
  }

  factory ManualFirmwareUpdateState.fromMap(Map<String, dynamic> map) {
    return ManualFirmwareUpdateState(
      file: map['file'] != null ? FileInfo.fromMap(map['file']) : null,
      status: map['status'] != null ? ManualUpdateStatus.fromMap(map['status']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ManualFirmwareUpdateState.fromJson(String source) =>
      ManualFirmwareUpdateState.fromMap(json.decode(source));

  @override
  String toString() =>
      'ManualFirmwareUpdateState(file: $file, status: $status)';

  @override
  List<Object?> get props => [file, status];
}
