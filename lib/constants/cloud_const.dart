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
const linksysCloudStatusBaseUrl = 'cloudhealth.lswf.net/cloud-availability';

// Linksys PROD
const kCloudEnvironmentConfigProd = {
  kCloudBase: 'cloud1.$linksysCloudBaseUrl',
  kCloudJNAP: 'https://cloud1.$linksysCloudBaseUrl/cloud/JNAP/',
  kCloudStatus: 'https://$linksysCloudStatusBaseUrl/cloud.json',
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