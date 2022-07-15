import 'package:moab_poc/network/http/model/cloud_config.dart';

// Moab Share Preferences keys
const moabPrefAppIdKey = 'MoabAppId';
const moabPrefAppSecretKey = 'MoabAppSecret';

// Moab header keys
const moabSiteIdKey = 'X-Linksys-Moab-Site-Id';
const moabAppIdKey = 'X-Linksys-Moab-App-Id';
const moabAppSecretKey = 'X-Linksys-Moab-App-Secret';
const moabClientIdKey = ''; // TODO TBD

// Moab header values
const moabRetailSiteId = 'b6b70875-9ec4-45eb-9792-2545ccc2bc5d';

const moabAppClientId = '991490F1-AD1D-47E0-81AD-190B11757252'; // TODO fake

const moabCloudConfigHost = 'https://config.linksys.cloud/';
const configFileName = 'environment.json';
const allConfigFileName = 'all-environments.json';

// Cloud config url
String get cloudConfigUrl => '$moabCloudConfigHost${cloudEnvTarget.name}/$configFileName';
String get allCloudConfigUrl => '$moabCloudConfigHost${cloudEnvTarget.name}/$allConfigFileName';

// Cloud path constants
const version = '/v1';
const accountPath = '/accounts';
const authPath = '/auth';

// Cloud endpoints variables
const varAccountId = '{accountId}';
const varVerifyToken = '{verifyToken}';
const varUsername = '{username}';

// Cloud endpoints
const endpointCreateApps = '$version/apps';
const endpointPostAccountPreparations = '$version$accountPath/verified-first/preparations';
const endpointPutAccountPreparations = '$version$accountPath/verified-first/preparations/$varVerifyToken';
const endpointPostCreateAccount = '$version$accountPath/verified-first/';

const endpointPostAuthChallenges = '$version$authPath/challenges';
const endpointPutAuthChallenges = '$version$authPath/challenges/verifications/$varVerifyToken';

const endpointPostLoginPrepare = '$version$authPath/login/prepare';
const endpointGetMaskedCommunicationMethods = '$version$accountPath/$varUsername/masked-communication-methods';
const endpointPostLoginPassword = '$version$authPath/login/password';
const endpointPostLogin = '$version$authPath/login';