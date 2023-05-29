import 'dart:io';

import 'build_config.dart';

const kCloudBase = 'CLOUD_BASE_URL';
const kCloudJNAP = 'CLOUD_JNAP_BASE_URL';
const kCloudStatus = 'CLOUD_STATUS_URL';
const kCloudAware = 'CLOUD_AWARE_URL';
const kCloudAwarePort = 'CLOUD_AWARE_PORT';
const kCloudAwareKey = 'CLOUD_AWARE_KEY';
const kCloudAwareScheme = 'CLOUD_AWARE_SCHEME';

const linksysCloudBaseUrl = 'linksyssmartwifi.com';
const linksysCloudStatusBaseUrl = 'cloudhealth.lswf.net/cloud-availability/';

// Linksys PROD
const kCloudEnvironmentConfigProd = {
  kCloudBase: 'cloud1.$linksysCloudBaseUrl',
  kCloudJNAP: 'https://cloud1.$linksysCloudBaseUrl/cloud/JNAP/',
  kCloudStatus: 'https://cloud1.$linksysCloudStatusBaseUrl/cloud.json',
  kCloudAware: 'aware.lswf.net',
  kCloudAwarePort: 3000,
  kCloudAwareKey: '339ec1249258dfd7e689',
  kCloudAwareScheme: 'https',
};
// Linksys QA
const kCloudEnvironmentConfigQa = {
  kCloudBase: 'qa.$linksysCloudBaseUrl',
  kCloudJNAP: 'https://qa.$linksysCloudBaseUrl/cloud/JNAP/',
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
  kCloudStatus: 'https://$linksysCloudStatusBaseUrl/cloud-dev.json',
  kCloudAware: 'staging.ds.veriksystems.com',
  kCloudAwarePort: 80,
  kCloudAwareKey: 'efeb0fd364285aaa1201',
  kCloudAwareScheme: 'http',
};
const Map<CloudEnvironment, dynamic> kCloudEnvironmentMap = {
  CloudEnvironment.prod: kCloudEnvironmentConfigProd,
  CloudEnvironment.qa: kCloudEnvironmentConfigQa,
  CloudEnvironment.dev: kCloudEnvironmentConfigDev,
};

// Variable replacements
const kVarGrantType = '{grantType}';
const kVarNetworkId = '{networkId}';
const kVarUsername = '{username}';

// Cloud API Service
const kAuthorizationService = '/cloud/authorization-service';
const kUserService = '/cloud/user-service';
const kDeviceService = '/cloud/device-service';

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
const kUserGetMfaMethods = '$kUserService/rest/accounts/self/mfa-methods';
const kUserGetAccount = '$kUserService/rest/accounts/self';
// Device service
const kDeviceNetworksEndpoint = '$kDeviceService/rest/networks/$kVarNetworkId';
const kAccountNetworksEndpoint = '$kDeviceService/rest/accounts/self/networks';

// Client type id/secret
final kClientTypeId = Platform.isIOS
    ? 'E918E731-F2CD-4A85-8CFA-1CD8C495939B'
    : 'B2101C5E-0E0C-4094-8BC5-6B97DE71C5BB';
final kClientSecret = Platform.isIOS
    ? "I6BVSkCrAvQCR6FjOxfxVDdhGcqTsJr2"
    : 'wm2HbbWXEx1zWPsdg2Rskzjr9Ps6GQ8y';

// Header keys
const kHeaderClientTypeId = 'X-Linksys-Client-Type-Id';
const kHeaderSignature = 'X-Linksys-Signature';
const kHeaderUserAgentId = 'X-Linksys-User-Agent-Id';
const kHeaderTimestamp = 'X-Linksys-Timestamp';

///

// Moab header keys
const moabSiteIdKey = 'X-Linksys-Moab-Site-Id';
const moabAppIdKey = 'X-Linksys-Moab-App-Id';
const moabAppSecretKey = 'X-Linksys-Moab-App-Secret';
const moabClientIdKey = ''; // TODO TBD
const moabTaskSecretKey = 'X-Linksys-Moab-Task-Secret';

// Moab header values
const moabRetailSiteId = 'b6b70875-9ec4-45eb-9792-2545ccc2bc5d';

const moabAppClientId = '991490F1-AD1D-47E0-81AD-190B11757252'; // TODO fake

const moabCloudConfigHost = 'https://config.linksys.cloud/';
// TODO #1 update resource url
String get moabCloudResourceHost =>
    'https://${cloudEnvTarget == CloudEnvironment.prod ? '' : ('${cloudEnvTarget.name}-')}resource.linksys.cloud';

const configFileName = 'environment.json';
const allConfigFileName = 'all-environments.json';
const regionCodesFileName = 'country-codes.json';
const webFilteringFileName = 'web-filters.json';
const securityCategoryPresetsFileName = 'security-category-presets.json';
const appSignaturesFileName = 'app-signatures.json';
const profilePresetsFilename = 'profile-presets.json';
// const profilePresetsFilename = 'profile-presets-temp.json';
const appIconsFilename = 'secure/icons.png';
const appIconKeysFilename = 'secure/icon-keys.json';

// Cloud config url
String get cloudConfigUrl =>
    '$moabCloudConfigHost${cloudEnvTarget.name}/$configFileName';

String get allCloudConfigUrl =>
    '$moabCloudConfigHost${cloudEnvTarget.name}/$allConfigFileName';

String get availabilityUrl =>
    'https://cloudhealth.lswf.net/cloud-availability/cloud-qa.json';

// Country code url
// String get countryCodeUrl => '$moabCloudConfigHost${cloudEnvTarget.name}/$regionCodesFileName';

// Content filtering urls
// String get webFilteringUrl => '$moabCloudConfigHost${cloudEnvTarget.name}/$webFilteringFileName';
// String get appSignaturesUrl => '$moabCloudConfigHost${cloudEnvTarget.name}/$appSignaturesFileName';
// String get categoryPresetsUrl =>'$moabCloudConfigHost${cloudEnvTarget.name}/$securityCategoryPresetsFileName';
// String get appIconsUrl => 'https://linksys.devvelopcloud.com/moab-assets/sprite-map.png'; //TBD
// String get profilePresetsUrl =>'$moabCloudConfigHost${cloudEnvTarget.name}/$profilePresetsFilename';

// AWS IoT root CA
String get awsIoTRootCA =>
    'https://www.amazontrust.com/repository/AmazonRootCA1.pem';

// Cloud path constants
const version = '/v1';
const accountPath = '/accounts';
const authPath = '/auth';
const tasksPath = '/tasks';
const primaryTasksPath = '/primary-tasks';
const verificationsPath = '/verifications';
const subscriptionPath = '/store';

// Cloud endpoints variables
const varAccountId = '{accountId}';
const varVerifyToken = '{verifyToken}';
const varUsername = '{username}';
const varTaskId = '{taskId}';
const varToken = '{token}';
const varAppId = '{appId}';
const varNetworkId = '{networkId}';
const varFlow = '{flow}';
const varMethod = '{method}';
const varTargetValue = '{targetValue}';
const varCertificateId = '{certificateId}';
const varSerialNumber = '{serialNumber}';

// Cloud endpoints
const endpointCreateApps = '$version/apps';
const endpointGetApps = '$version/apps/$varAppId';
const endpointPutSmartDevices = '$version/apps/$varAppId/smart-devices';
const endpointPutAcceptSmartDevices =
    '$version/apps/$varAppId/smart-devices/ACCEPTED';
const endpointPostAcceptEULA = '$version/apps/$varAppId/eula/$varNetworkId';
const endpointPostCertExtensions =
    '$version$authPath/certificates/$varCertificateId/extensions';
const endpointPostCertSessions =
    '$version$authPath/certificates/$varCertificateId/sessions';

const endpointPostAccountPreparations =
    '$version$accountPath/verified-first/preparations';
const endpointPutAccountPreparations =
    '$version$accountPath/verified-first/preparations/$varVerifyToken';
const endpointPostCreateAccount = '$version$accountPath/verified-first/';

const endpointPostAuthChallenges = '$version$authPath/challenges';
const endpointPutAuthChallenges =
    '$version$authPath/challenges/verifications/$varVerifyToken';
const endpointPutVerificationAccept =
    '$version$verificationsPath/$varVerifyToken/ACCEPTED';

const endpointPostLoginPrepare = '$version$authPath/login/prepare';
const endpointGetMaskedCommunicationMethods =
    '$version$accountPath/masked-communication-methods?username=$varUsername';
const endpointPostLoginPassword = '$version$authPath/login/password';
const endpointPostLogin = '$version$authPath/login';
const endpointGetTasks = '$version$tasksPath/$varTaskId?token=$varToken';
const endPointGetPrimaryTasks = '$version$primaryTasksPath/$varTaskId';
const endpointGetAccountSelf = '$version$accountPath/self';
const endpointPostCommunicationMethods =
    '$version$accountPath/$varAccountId/communication-methods?flow=$varFlow';
const endpointDeleteAuthCommunicationMethod =
    '$version$accountPath/$varAccountId/communication-methods?method=$varMethod&targetValue=$varTargetValue';
const endpointPostChangePassword =
    '$version$accountPath/$varAccountId/password/change';
const endpointPreferences = '$version$accountPath/$varAccountId/preferences';
const endpointDefaultNetworkGroup =
    '$version$accountPath/$varAccountId/network-groups/DEFAULT';
const endpointAuthenticationModePrepare =
    '$version$accountPath/$varAccountId/authentication-mode/prepare';
const endpointAuthenticationModeChange =
    '$version$accountPath/$varAccountId/authentication-mode';

const endpointGetNetworks = '$version$accountPath/$varAccountId/networks';
const endpointGetNetworkById =
    '$version$accountPath/$varAccountId/networks/$varNetworkId';

const endpointSubscriptionQueryProductListings =
    '$version$subscriptionPath/product-listings';
const endpointSubscriptionCreateCloudOrders =
    '$version$subscriptionPath/orders';
const endpointSubscriptionGetNetworkEntitlement =
    '$version$subscriptionPath/network-serial-numbers/$varSerialNumber/entitlements';
//
const keyRequire2sv = 'REQUIRE_2SV';
const keyPasswordRequired = 'PASSWORD_REQUIRED';
