import 'build_config.dart';

import 'client_type/client_type.dart';

const kCloudBase = 'CLOUD_BASE_URL';
const kFirmwareOtaBase = 'FIRMWARE_OTA_BASE_URL';

const linksysDomain = 'cloud1.linksyssmartwifi.com';
const guardianDomain = 'guardian.tools'; // TODO: switch when ready
const domainBase = linksysDomain;

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
const kVarGrantType = '{grantType}';
const kVarNetworkId = '{networkId}';
const kVarUsername = '{username}';
const kVarToken = '{token}';
const kVarEventSubscriptionId = '{eventSubscriptionId}';
const kVarId = '{id}';
const kVarRASessionId = '{remoteassistancesessionId}';

// Cloud API Service
const kAuthorizationService = '/cloud/authorization-service';
const kUserService = '/cloud/user-service';
const kDeviceService = '/cloud/device-service';
const kSmartDeviceService = '/cloud/smart-device-service';
const kEventService = '/cloud/event-service';
const kAssetService = '/cloud/asset-service';
const kStorageService = '/cloud/storage-service';

/// Cloud API Endpoint
// Authorization service
const kOauthEndpoint =
    '$kAuthorizationService/oauth/v2/token?grant_type=$kVarGrantType';
const kOauthChallengeEndpoint = '$kAuthorizationService/oauth/challenge';
// User service
const kUserAccountEndpoint =
    '$kUserService/rest/v2/accounts/u?purpose=CLOUD_ACCT_SETUP';
const kUserAccountPreferencesEndpoint =
    '$kUserService/rest/accounts/self/preferences';
const kUserPhoneCallingCodesEndpoint = '$kUserService/rest/phonecallingcodes';
const kUserPhoneNumberCheckEndpoint = '$kUserService/rest/phonenumbercheck';
const kUserGetMaskedMfaMethods =
    '$kUserService/rest/accounts/$kVarUsername/masked-mfa-methods';
const kUserMfaMethods = '$kUserService/rest/accounts/self/mfa-methods';
const kUserMfaMethodsDelete = '$kUserMfaMethods/$kVarId';
const kUserMfaValidate = '$kUserService/rest/accounts/self/mfa-validate';
const kUserGetAccount = '$kUserService/rest/accounts/self';
// test ping.png
const kTestPingPng = '/cloud/ping.png';

// Device service
const kDeviceNetworksEndpoint = '$kDeviceService/rest/networks/$kVarNetworkId';
const kAccountNetworksEndpoint = '$kDeviceService/rest/accounts/self/networks';

// Smart device service
const kSmartDeviceRegisterEndpoint = '$kSmartDeviceService/rest/smartdevices';
const kSmartDeviceVerificationEndpoint =
    '$kSmartDeviceService/rest/verifications/$kVarToken/status';
// Event service
const kEventeSubscriptionCreate =
    '$kEventService/rest/clients/self/accounts/self/networks/$kVarNetworkId/eventsubscriptions';
const kEventNetworkActionCreate =
    '$kEventService/rest/eventsubscriptions/$kVarEventSubscriptionId/actions';
// Asset service
const kFetchLinkup = '$kAssetService/rest/assets/linkup';
// Firmware OTA
const kFirmwareOtaEndpoint = '/api/v2/fw/update';

// NEW smart device
const kSmartDeviceAssociate = '/cloud/v1/smart-devices/associate';

/// Guardians

// Geo location
const kGeoLocation = '/cloud/v1/guardians/devices/geolocation';
const kDeviceToken = '/cloud/v1/guardians/devices/tokens';

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
