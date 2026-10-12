/// Thrown when the user cancels a local firmware upload.
///
/// A model rather than part of the upload service, because the view catches it
/// to tell a cancel from a failure, and views may not depend on services
/// (constitution §5.4).
class FirmwareUploadCancelledException implements Exception {
  const FirmwareUploadCancelledException();

  @override
  String toString() => 'Firmware upload cancelled by user';
}
