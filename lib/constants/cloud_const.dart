import 'package:linksys_moab/network/http/model/cloud_config.dart';

import 'build_config.dart';

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
const configFileName = 'environment.json';
const allConfigFileName = 'all-environments.json';
const countryCodeFileName = 'country-codes.json';
const webFilteringFileName = 'web-filters.json';
const securityCategoryPresetsFileName = 'security-category-presets.json';
const appSignaturesFileName = 'app-signatures.json';

// Cloud config url
String get cloudConfigUrl => '$moabCloudConfigHost${cloudEnvTarget.name}/$configFileName';
String get allCloudConfigUrl => '$moabCloudConfigHost${cloudEnvTarget.name}/$allConfigFileName';
String get availabilityUrl => 'https://cloudhealth.lswf.net/cloud-availability/cloud-qa.json';

// Country code url
String get countryCodeUrl => '$moabCloudConfigHost${cloudEnvTarget.name}/$countryCodeFileName';

// Content filtering urls
String get webFilteringUrl => '$moabCloudConfigHost${cloudEnvTarget.name}/$webFilteringFileName';
String get appSignaturesUrl => '$moabCloudConfigHost${cloudEnvTarget.name}/$appSignaturesFileName';
String get wcfPresetsUrl =>'$moabCloudConfigHost${cloudEnvTarget.name}/$securityCategoryPresetsFileName';

// Cloud path constants
const version = '/v1';
const accountPath = '/accounts';
const authPath = '/auth';
const tasksPath = '/tasks';
const primaryTasksPath = '/primary-tasks';
const verificationsPath = '/verifications';

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

// Cloud endpoints
const endpointCreateApps = '$version/apps';
const endpointGetApps = '$version/apps/$varAppId';
const endpointPutSmartDevices = '$version/apps/$varAppId/smart-devices';
const endpointPutAcceptSmartDevices = '$version/apps/$varAppId/smart-devices/ACCEPTED';
const endpointPostAcceptEULA = '$version/apps/$varAppId/eula/$varNetworkId';
const endpointPostCertExtensions = '$version$authPath/certificates/$varCertificateId/extensions';
const endpointPostCertSessions = '$version$authPath/certificates/$varCertificateId/sessions';

const endpointPostAccountPreparations = '$version$accountPath/verified-first/preparations';
const endpointPutAccountPreparations = '$version$accountPath/verified-first/preparations/$varVerifyToken';
const endpointPostCreateAccount = '$version$accountPath/verified-first/';

const endpointPostAuthChallenges = '$version$authPath/challenges';
const endpointPutAuthChallenges = '$version$authPath/challenges/verifications/$varVerifyToken';
const endpointPutVerificationAccept = '$version$verificationsPath/$varVerifyToken/ACCEPTED';

const endpointPostLoginPrepare = '$version$authPath/login/prepare';
const endpointGetMaskedCommunicationMethods = '$version$accountPath/masked-communication-methods?username=$varUsername';
const endpointPostLoginPassword = '$version$authPath/login/password';
const endpointPostLogin = '$version$authPath/login';
const endpointGetTasks = '$version$tasksPath/$varTaskId?token=$varToken';
const endPointGetPrimaryTasks = '$version$primaryTasksPath/$varTaskId';
const endpointGetAccountSelf = '$version$accountPath/self';
const endpointPostCommunicationMethods = '$version$accountPath/$varAccountId/communication-methods?flow=$varFlow';
const endpointDeleteAuthCommunicationMethod = '$version$accountPath/$varAccountId/communication-methods?method=$varMethod&targetValue=$varTargetValue';
const endpointPostChangePassword = '$version$accountPath/$varAccountId/password/change';
const endpointPreferences = '$version$accountPath/$varAccountId/preferences';
//
const keyRequire2sv = 'REQUIRE_2SV';
const keyPasswordRequired ='PASSWORD_REQUIRED';