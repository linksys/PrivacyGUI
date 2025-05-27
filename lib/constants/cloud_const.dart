import 'build_config.dart';

import 'client_type/get_client_type.dart'
    if (dart.library.io) 'client_type/mobile_client_type.dart'
    if (dart.library.html) 'client_type/web_client_type.dart';

const kCloudBase = 'CLOUD_BASE_URL';
const kCloudJNAP = 'CLOUD_JNAP_BASE_URL';
const kCloudRemoteJNAP = 'CLOUD_REMOTE_JNAP_BASE_URL';
const kCloudStatus = 'CLOUD_STATUS_URL';
const kCloudAware = 'CLOUD_AWARE_URL';
const kCloudAwarePort = 'CLOUD_AWARE_PORT';
const kCloudAwareKey = 'CLOUD_AWARE_KEY';
const kCloudAwareScheme = 'CLOUD_AWARE_SCHEME';

const linksysCloudBaseUrl = 'linksyssmartwifi.com';
const linksysCloudStatusBaseUrl = 'cloudhealth.lswf.net/cloud-availability';

// Linksys PROD
const kCloudEnvironmentConfigProd = {
  kCloudBase: 'cloud1.$linksysCloudBaseUrl',
  kCloudJNAP: 'https://cloud1.$linksysCloudBaseUrl/cloud/JNAP/',
  kCloudRemoteJNAP:
      'https://cloud1.$linksysCloudBaseUrl/cloud/v1/guardians/remote-assistances/sessions/$kVarRASessionId/actions/jnap/',
  kCloudStatus: 'https://$linksysCloudStatusBaseUrl/cloud.json',
  kCloudAware: 'aware.lswf.net',
  kCloudAwarePort: 3000,
  kCloudAwareKey: '339ec1249258dfd7e689',
  kCloudAwareScheme: 'https',
};
// Linksys QA
const kCloudEnvironmentConfigQa = {
  kCloudBase: 'qa.cloud1.$linksysCloudBaseUrl',
  kCloudJNAP: 'https://qa.cloud1.$linksysCloudBaseUrl/cloud/JNAP/',
  kCloudRemoteJNAP:
      'https://qa.cloud1.$linksysCloudBaseUrl/cloud/v1/guardians/remote-assistances/sessions/$kVarRASessionId/actions/jnap/',
  kCloudStatus: 'https://$linksysCloudStatusBaseUrl/cloud-qa.json',
  kCloudAware: 'staging.ds.veriksystems.com',
  kCloudAwarePort: 80,
  kCloudAwareKey: '372851d642c0f179905e',
  kCloudAwareScheme: 'http',
};
// Linksys DEV
const kCloudEnvironmentConfigDev = {
  kCloudBase: 'dev.$linksysCloudBaseUrl',
  kCloudJNAP: 'https://dev.$linksysCloudBaseUrl/cloud/JNAP/',
  kCloudRemoteJNAP:
      'https://dev.cloud1.$linksysCloudBaseUrl/cloud/v1/guardians/remote-assistances/sessions/$kVarRASessionId/actions/jnap/',
  kCloudStatus: 'https://$linksysCloudStatusBaseUrl/cloud-dev.json',
  kCloudAware: 'staging.ds.veriksystems.com',
  kCloudAwarePort: 80,
  kCloudAwareKey: 'efeb0fd364285aaa1201',
  kCloudAwareScheme: 'http',
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
const kTicketId = '{ticketId}';
const kVarRASessionId = '{remoteassistancesessionId}';

// Cloud API Service
const kAuthorizationService = '/cloud/authorization-service';
const kUserService = '/cloud/user-service';
const kDeviceService = '/cloud/device-service';
const kSmartDeviceService = '/cloud/smart-device-service';
const kEventService = '/cloud/event-service';
const kAssetService = '/cloud/asset-service';
const kStorageService = '/cloud/storage-service';
const kRemoteAssistanceService = '/cloud/remote-access-service';

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
const kDeviceRegistrationsEndpoint =
    '$kDeviceService/rest/devices/registrations';
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
// Storage service
const kDeviceUpload =
    '$kStorageService/rest/deviceuploads?uploadType=MOBILE_LOG';
// Remote assistance
const kRASessions = '$kRemoteAssistanceService/rest/remoteassistance/sessions';
const kRAAccountInfo =
    '$kRemoteAssistanceService/rest/remoteassistance/sessions/$kVarRASessionId/accountinfo';
const kRASessionInfo =
    '$kRemoteAssistanceService/rest/remoteassistance/sessions/$kVarRASessionId';
const kRATemporaryRAS =
    '$kRemoteAssistanceService/rest/remoteassistance/temporaryras';
const kRASendPin =
    '$kRemoteAssistanceService/rest/remoteassistance/sessions/sendpin';
const kRAPin = '$kRemoteAssistanceService/rest/remoteassistance/sessions/pin';
// Create Ticket
const kTickets = '/cloud/v1/tickets';
const kGetTicketDetails = '/cloud/v1/tickets/$kTicketId';
const kCreateTicketUpload = '/cloud/v1/tickets/$kTicketId/uploads';

// NEW smart device
const kSmartDeviceAssociate = '/cloud/v1/smart-devices/associate';

/// Guardians

// Geo location
const kGeoLocation = '/cloud/v1/guardians/devices/geolocation';

// Remote assistance
const kSessions = '/cloud/v1/guardians/remote-assistances/sessions';
const kSessionInfo =
    '/cloud/v1/guardians/remote-assistances/sessions/$kVarRASessionId';

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
const kHeaderNetworkId = 'X-Linksys-Network-Id';

///
