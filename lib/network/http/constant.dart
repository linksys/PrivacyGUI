import 'package:moab_poc/network/http/model/cloud_config.dart';

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

// Cloud endpoints
const endpointCreateApps = '$version/apps';
const endpointAccountPreparations = '$version$accountPath/verified-first/preparations';
const endpointAuthLoginPrepare = '$version$authPath/login/prepare';
