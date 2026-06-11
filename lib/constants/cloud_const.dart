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
