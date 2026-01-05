/// Access level for router commands.
enum AccessLevel {
  /// Read-only operations, no confirmation needed
  read,

  /// Write operations, requires user confirmation
  write,

  /// Administrative operations, requires double confirmation
  admin,
}
