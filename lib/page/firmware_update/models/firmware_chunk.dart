import 'dart:typed_data';
import 'package:equatable/equatable.dart';

class FirmwareChunk extends Equatable {
  final int sequenceNumber;
  final int totalFragment;
  final Uint8List data;

  const FirmwareChunk({
    required this.sequenceNumber,
    required this.totalFragment,
    required this.data,
  });

  @override
  List<Object?> get props => [sequenceNumber, totalFragment, data.length];
}
