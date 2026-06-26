enum FirmwareUpdatePhase {
  idle,
  checkingOta,
  picking,
  validating,
  uploading,
  triggering,
  installing,
  rebooting,
  verifying,
  done,
  failed,
}
