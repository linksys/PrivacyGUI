import 'build_config.dart';

import 'client_type/client_type.dart';

const kCloudBase = 'CLOUD_BASE_URL';
const kFirmwareOtaBase = 'FIRMWARE_OTA_BASE_URL';

const linksysDomain = 'cloud1.linksyssmartwifi.com';
const guardianDomain = 'guardian.tools';
const domainBase = guardianDomain;

// Linksys PROD
const kCloudEnvironmentConfigProd = {
  kCloudBase: domainBase,
  kFirmwareOtaBase: 'https://update.linksys.com',
};
// Linksys QA
const kCloudEnvironmentConfigQa = {
  kCloudBase: 'qa.$domainBase',
  kFirmwareOtaBase: 'https://update-stage.linksys.com',
};
// Linksys DEV
const kCloudEnvironmentConfigDev = {
  kCloudBase: 'dev.$domainBase',
  kFirmwareOtaBase: 'https://update-stage.linksys.com',
};
const Map<CloudEnvironment, dynamic> kCloudEnvironmentMap = {
  CloudEnvironment.prod: kCloudEnvironmentConfigProd,
  CloudEnvironment.qa: kCloudEnvironmentConfigQa,
  // CloudEnvironment.dev: kCloudEnvironmentConfigDev,
};

// Variable replacements
const kVarRASessionId = '{remoteassistancesessionId}';

// Firmware OTA
const kFirmwareOtaEndpoint = '/api/v2/fw/update';

/// Guardians

// Device token
const kDeviceToken = '/v1/guardians/devices/tokens';

// Remote assistance - Guardian API (Client side)
const kSessions = '/v1/guardians/remote-assistances/sessions';
const kSessionInfo =
    '/v1/guardians/remote-assistances/sessions/$kVarRASessionId';
const kCreatePin = '/v1/guardians/remote-assistances/sessions/pin';

/// Path prefix for the router's reverse proxy to cloud (same-origin), used only
/// for client-side RA requests on a local web build so the browser avoids CORS.
/// Verified end-to-end against QA + Production + router FW (see issue #1179);
/// kept as a single point of change should the FW prefix ever move.
/// Must NOT end with a trailing slash (endpoints already start with '/').
const kProxyPrefix = '/cloud';

// Client type id/secret
final kClientTypeId = clientTypeID;
final kClientSecret = clientTypeSecret;

// Header keys
const kHeaderClientTypeId = 'X-Linksys-Client-Type-Id';
const kHeaderSignature = 'X-Linksys-Signature';
const kHeaderUserAgentId = 'X-Linksys-User-Agent-Id';
const kHeaderTimestamp = 'X-Linksys-Timestamp';
const kHeaderLinksysToken = 'X-Linksys-Token';
const kHeaderSerialNumber = 'X-Linksys-SN';
