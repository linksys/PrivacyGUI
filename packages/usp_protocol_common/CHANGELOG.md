# Changelog

## 1.0.0

- Initial release of the `usp_protocol_common` library.
- Provides type-safe Dart DTOs for all standard USP messages (Get, Set, Add, Delete, Operate, Error).
- Includes converters for serializing and deserializing messages to and from the Protobuf wire format.
- Implements value objects for handling USP paths and values.
- Provides a stateless path resolver for searching tree-like data structures.