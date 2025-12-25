# Quickstart Guide: USP Protocol Common Core Library

This guide provides a rapid introduction to using the `usp_protocol_common` library in your Dart or Flutter project.

## 1. Installation

Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  usp_protocol_common: ^latest_version # Replace with the latest published version
  json_annotation: ^latest_version
  protobuf: ^latest_version
  equatable: ^latest_version

dev_dependencies:
  build_runner: ^latest_version
  json_serializable: ^latest_version
```

Then run `flutter pub get` (or `dart pub get`) to install the dependencies.

## 2. Generating Code

If you modify any `.proto` files or the `json_serializable` annotated Dart classes, you will need to regenerate the code. Run the following command in your project root:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
For continuous generation during development, use:
```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

## 3. Basic Usage: `UspPath`

`UspPath` represents a hierarchical path within the USP data model.

```dart
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  // Creating a UspPath
  final path1 = UspPath("Device.LocalAgent.Endpoint.{i}.Manufacturer");
  print('Path 1: $path1'); // Output: Device.LocalAgent.Endpoint.{i}.Manufacturer

  // Path normalization: trailing dots are removed
  final path2 = UspPath("Device.LocalAgent.");
  print('Path 2: $path2'); // Output: Device.LocalAgent

  // Wildcard path
  final wildcardPath = UspPath("Device.LocalAgent.Endpoint.*.Manufacturer");
  print('Wildcard Path: $wildcardPath');

  // Path validation
  try {
    UspPath("Invalid.Path..String"); // This will throw a UspException
  } on UspException catch (e) {
    print('Path validation error: ${e.message}');
  }
}
```

## 4. Basic Usage: `UspValue`

`UspValue` encapsulates different data types.

```dart
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  // Create UspValue from different types
  final stringValue = UspValue.fromString("hello");
  final intValue = UspValue.fromInt(123);
  final boolValue = UspValue.fromBool(true);
  final binaryValue = UspValue.fromBinary([0x01, 0x02, 0x03]);

  print('String Value: ${stringValue.value}, Type: ${stringValue.type}');
  print('Int Value: ${intValue.value}, Type: ${intValue.type}');
  print('Bool Value: ${boolValue.value}, Type: ${boolValue.type}');
  print('Binary Value: ${binaryValue.value}, Type: ${binaryValue.type}');

  // JSON Serialization (UspValue handles type information)
  final jsonString = stringValue.toJson();
  print('JSON for String Value: $jsonString');
  // Example output: {"value":"hello","type":"STRING"}

  // JSON Deserialization
  final decodedValue = UspValue.fromJson(json.decode('{"value":123,"type":"INT"}'));
  print('Decoded Int Value: ${decodedValue.value}');
}
```

## 5. Basic Usage: USP Messages (DTOs)

This section demonstrates how to create and handle USP Request/Response DTOs.

```dart
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:usp_protocol_common/src/dtos/requests/get_request.dart';
import 'package:usp_protocol_common/src/dtos/responses/get_response.dart';
import 'package:usp_protocol_common/src/dtos/responses/error_response.dart';
import 'package:usp_protocol_common/src/dtos/usp_message.dart'; // Assuming a base UspMessage class

void main() {
  // Create a UspGetRequest
  final getRequest = UspGetRequest(
    paths: [
      UspPath("Device.DeviceInfo.Manufacturer"),
      UspPath("Device.LocalAgent.Endpoint.*.ID"),
    ],
  );

  // You can compare DTOs for value equality
  final anotherGetRequest = UspGetRequest(
    paths: [
      UspPath("Device.DeviceInfo.Manufacturer"),
      UspPath("Device.LocalAgent.Endpoint.*.ID"),
    ],
  );
  print('Are getRequests equal? ${getRequest == anotherGetRequest}'); // Output: true

  // Simulate a UspGetResponse
  final getResponse = UspGetResponse(
    records: [
      UspRecord(
        id: "msg1",
        senderId: "agent123",
        receiverId: "controller456",
        message: getRequest, // In a real scenario, this would be the actual response message
      ),
      UspRecord(
        id: "msg2",
        senderId: "agent123",
        receiverId: "controller456",
        message: UspErrorResponse(
          errorCode: 7000,
          errorMessage: "Object not found",
        ),
      ),
    ],
  );

  // Accessing message content using type checking
  getResponse.records.forEach((record) {
    final message = record.message;
    if (message is UspGetRequest) {
      print('Received a Get Request for paths: ${message.paths}');
    } else if (message is UspErrorResponse) {
      print('Received an Error: ${message.errorMessage} (Code: ${message.errorCode})');
    } else {
      print('Received an unknown message type: ${message.runtimeType}');
    }
  });
}
```

## 6. Serialization and Deserialization (Protobuf)

This library provides converters to translate between Dart DTOs and their Protobuf binary representations.

```dart
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:usp_protocol_common/src/converter/usp_protobuf_converter.dart';
import 'package:usp_protocol_common/src/dtos/requests/get_request.dart';
import 'package:usp_protocol_common/src/generated/usp_msg.pb.dart' as pb;

void main() {
  // 1. Create a Dart DTO
  final getRequestDto = UspGetRequest(
    paths: [
      UspPath("Device.DeviceInfo.Manufacturer"),
    ],
  );

  // 2. Convert DTO to Protobuf message
  final pbMsg = UspProtobufConverter.toProtobuf(getRequestDto);
  print('Protobuf Message type: ${pbMsg.body.request.whichBody()}');

  // 3. Serialize Protobuf message to binary (List<int>)
  final binaryData = pbMsg.writeToBuffer();
  print('Binary data: $binaryData');

  // 4. Deserialize binary data back to Protobuf message
  final decodedPbMsg = pb.Msg.fromBuffer(binaryData);

  // 5. Convert Protobuf message back to Dart DTO
  final decodedDto = UspProtobufConverter.fromProtobuf(decodedPbMsg);

  print('Are original and decoded DTOs equal? ${getRequestDto == decodedDto}'); // Output: true
}
```
