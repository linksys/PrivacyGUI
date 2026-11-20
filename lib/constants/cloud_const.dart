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
// test ping.png
const kTestPingPng = '/cloud/ping.png';

// Remote assistance
const kRASessions = '$kRemoteAssistanceService/rest/remoteassistance/sessions';
const kRASessionInfo =
    '$kRemoteAssistanceService/rest/remoteassistance/sessions/$kVarRASessionId';
const kRAPin = '$kRemoteAssistanceService/rest/remoteassistance/sessions/pin';
// Create Ticket
const kTickets = '/cloud/v1/tickets';
const kGetTicketDetails = '/cloud/v1/tickets/$kTicketId';
const kCreateTicketUpload = '/cloud/v1/tickets/$kTicketId/uploads';

/// Guardians

// Geo location
const kGeoLocation = '/cloud/v1/guardians/devices/geolocation';
const kDeviceToken = '/cloud/v1/guardians/devices/tokens';

// Remote assistance
const kSessions = '/cloud/v1/guardians/remote-assistances/sessions';
const kSessionInfo =
    '/cloud/v1/guardians/remote-assistances/sessions/$kVarRASessionId';
const kCreatePin = '/cloud/v1/guardians/remote-assistances/sessions/pin';

// Client type id
final kClientTypeId = clientTypeID;

// Header keys
const kHeaderClientTypeId = 'X-Linksys-Client-Type-Id';
const kHeaderLinksysToken = 'X-Linksys-Token';
const kHeaderSerialNumber = 'X-Linksys-SN';
const kHeaderNetworkId = 'X-Linksys-Network-Id';

///
