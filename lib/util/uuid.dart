import 'package:uuid/uuid.dart';

/// A globally accessible, constant instance of the [Uuid] class.
///
/// This instance can be used throughout the application to generate unique
/// identifiers without needing to create a new [Uuid] object each time.
///
/// Example:
/// ```dart
/// String newId = uuid.v4();
/// ```
const Uuid uuid = Uuid();
